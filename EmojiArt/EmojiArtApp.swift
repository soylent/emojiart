//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by soylent on 6/13/23.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    @StateObject var document = EmojiArtDocument()
    @StateObject var paletteStore = PaletteStore(name: "Default")

    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
                .environmentObject(paletteStore)
        }
    }
}
