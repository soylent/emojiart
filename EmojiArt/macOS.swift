//
//  macOS.swift
//  EmojiArt
//
//  Created by soylent on 7/14/23.
//

import SwiftUI

typealias UIImage = NSImage
typealias PaletteManager = EmptyView

extension Image {
    init(uiImage: UIImage) {
        self.init(nsImage: uiImage)
    }
}

extension UIImage {
    var imageData: Data? { tiffRepresentation }
}

extension View {
    func wrappedInNavigationStackToMakeDismissable(_ dismiss: (() -> Void)?) -> some View {
        self
    }

    func paletteControlButtonStyle() -> some View {
        buttonStyle(PlainButtonStyle()).foregroundColor(.accentColor).padding(.vertical)
    }

    func popoverPadding() -> some View {
        padding(.horizontal)
    }
}

/// Unavailable photo picker.
struct CantDoItPhotoPicker: View {
    static let isAvailable = false

    var handlePickedImage: (UIImage?) -> Void

    var body: some View {
        EmptyView()
    }
}

typealias Camera = CantDoItPhotoPicker
typealias PhotoLibrary = CantDoItPhotoPicker

/// Cross-platform pasteboard.
struct Pasteboard {
    static var imageData: Data? {
        NSPasteboard.general.data(forType: .tiff) ?? NSPasteboard.general.data(forType: .png)
    }

    static var imageURL: URL? {
        (NSURL(from: NSPasteboard.general) as URL?)?.imageURL
    }
}
