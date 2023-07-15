//
//  iOS.swift
//  EmojiArt
//
//  Created by soylent on 7/14/23.
//

import SwiftUI

extension UIImage {
    var imageData: Data? { jpegData(compressionQuality: 1.0) }
}

extension View {
    func paletteControlButtonStyle() -> some View {
        self
    }

    func popoverPadding() -> some View {
        self
    }
    
    @ViewBuilder
    func wrappedInNavigationStackToMakeDismissable(_ dismiss: (() -> Void)?) -> some View {
        if let dismiss, UIDevice.current.userInterfaceIdiom != .pad {
            NavigationStack {
                self
                    .navigationBarTitleDisplayMode(.inline)
                    .dismissable(dismiss)
            }
        } else {
            self
        }
    }

    @ViewBuilder
    func dismissable(_ dismiss: (() -> Void)?) -> some View {
        if let dismiss, UIDevice.current.userInterfaceIdiom != .pad {
            self.toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        } else {
            self
        }
    }
}

/// Cross-platform pasteboard.
struct Pasteboard {
    static var imageData: Data? {
        UIPasteboard.general.image?.jpegData(compressionQuality: 1.0)
    }

    static var imageURL: URL? {
        UIPasteboard.general.url?.imageURL
    }
}
