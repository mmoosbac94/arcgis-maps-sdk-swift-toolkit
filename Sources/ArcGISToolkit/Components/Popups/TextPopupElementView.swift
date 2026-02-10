// Copyright 2022 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import SwiftUI
import ArcGIS

func isHTML(_ string: String) -> Bool {
    let pattern = "<([A-Za-z][A-Za-z0-9]*)\\b[^>]*>(.*?)</\\1>"
    return string.range(of: pattern, options: .regularExpression) != nil
}

/// A view displaying a `TextPopupElement`.
struct TextPopupElementView: View {
    /// The `PopupElement` to display.
    let popupElement: TextPopupElement
    
    /// The calculated height of the `HTMLTextView`.
    @State private var webViewHeight: CGFloat?
    
    var body: some View {
        if isHTML(popupElement.text) {
            ZStack {
                HTMLTextView(html: popupElement.text, height: $webViewHeight)
                    .frame(height: webViewHeight ?? .zero)
                if webViewHeight == .zero {
                    // Show `ProgressView` until `HTMLTextView` has set the height.
                    ProgressView()
                }
            }
        } else {
            FormattedValueText(formattedValue: popupElement.text)
        }
    }
    
    // Duplicate code: view is also in FieldsPopupElementView!
    private struct FormattedValueText: View {
        
        let formattedValue: String
        private let detector = PopupValueDetector()
        
        var body: some View {
            switch detector.detect(in: formattedValue) {
                
            case .fullURL(let url):
                Link(destination: url) {
                    Text(
                        "View",
                        bundle: .toolkitModule,
                        comment: "E.g. Open a hyperlink."
                    )
                }
#if os(visionOS)
                .buttonStyle(.bordered)
#else
                .buttonStyle(.borderless)
#endif
                
            case .inlineLinks(let links):
                Text(attributedText(links: links))
                
            case .none:
                Text(formattedValue)
            }
        }
        
        private func attributedText(
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
    }
}
