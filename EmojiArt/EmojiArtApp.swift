//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by user on 6/13/23.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    var body: some Scene {
        let document = EmojiArtDocument()
        let paletteStore = PaletteStore(name: "Default")

        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
