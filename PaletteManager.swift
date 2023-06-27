//
//  PaletteManager.swift
//  EmojiArt
//
//  Created by user on 6/26/23.
//

import SwiftUI

struct PaletteManager: View {
    @EnvironmentObject var store: PaletteStore

    var body: some View {
        NavigationStack {
            List(store.palettes) { palette in
                NavigationLink {
                    PaletteEditor(palette: $store.palettes[palette])
                } label: {
                    VStack(alignment: .leading) {
                        Text(palette.name)
                        Text(palette.emojis)
                    }
                }
            }
            .navigationTitle("Manage Palettes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct PaletteManager_Previews: PreviewProvider {
    static var previews: some View {
        PaletteManager()
            .environmentObject(PaletteStore(name: "Preview"))
    }
}
