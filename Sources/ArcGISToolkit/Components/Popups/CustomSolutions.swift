//
//  CustomSolutions.swift
//  arcgis-maps-sdk-swift-toolkit
//
//  Created by Tim Schaal on 10.02.26.
//

import Foundation
import SwiftUI


struct PopupValueDetector {
    
    enum DetectedValue {
        case fullURL(URL)
        case inlineLinks([(url: URL, range: NSRange)])
    }
    
    func detect(in text: String) -> DetectedValue? {
        
        /// Full-string URL
        if text.lowercased().starts(with: "http"),
           let url = URL(string: text) {
            return .fullURL(url)
        }
        
        let types: NSTextCheckingResult.CheckingType = [.phoneNumber, .link]
        guard let detector = try? NSDataDetector(types: types.rawValue) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)
        
        let links: [(URL, NSRange)] = matches.compactMap { match in
            
            /// http(s) or mailto
            if let url = match.url {
                return (url, match.range)
            }
            
            /// phone → tel:
            if let phone = match.phoneNumber {
                let cleaned = phone
                    .components(separatedBy: CharacterSet.decimalDigits.inverted)
                    .joined()
                
                return URL(string: "tel:\(cleaned)").map {
                    ($0, match.range)
                }
            }
            
            return nil
        }
        
        return links.isEmpty ? nil : .inlineLinks(links)
    }
    
}

func attributedText(
    formattedValue: String,
    links: [(url: URL, range: NSRange)]
) -> AttributedString {
    var attributed = AttributedString(formattedValue)
    
    for link in links {
        if let range = Range(link.range, in: attributed) {
            attributed[range].link = link.url
            attributed[range].foregroundColor = .blue
            attributed[range].underlineStyle = .single
        }
    }
    
    return attributed
}

extension View {
    func copyContextMenu(_ string: String) -> some View {
        self.contextMenu {
            Button("Kopieren") {
                Pasteboard.copy(string)
            }
        }
    }
}

enum Pasteboard {
    static func copy(_ string: String) {
#if os(iOS) || os(tvOS) || os(visionOS)
        UIPasteboard.general.string = string
#elseif os(macOS)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(string, forType: .string)
#endif
    }
}

