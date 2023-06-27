//
//  PaletteEditor.swift
//  EmojiArt
//
//  Created by user on 6/25/23.
//

import SwiftUI

struct PaletteEditor: View {
    @Binding var palette: Palette
    @State private var emojisToAdd = ""

    var body: some View {
        Form {
            nameSection
            addEmojiSection
        }
        .frame(minWidth: 300, minHeight: 350)
    }

    private var nameSection: some View {
        Section(header: Text("Name")) {
            TextField("Name", text: $palette.name)
        }
    }

    private var addEmojiSection: some View {
        Section(header: Text("Add Emojis")) {
            TextField("", text: $emojisToAdd)
                .onChange(of: emojisToAdd) { emojis in
                    withAnimation {
                        palette.emojis = (emojis + palette.emojis)
                            .filter { $0.isEmoji }
                            .withNoRepeatedCharacters
                    }

                }
        }
    }
}

struct PaletteEditor_Previews: PreviewProvider {
    static var previews: some View {
        PaletteEditor(palette: .constant(PaletteStore(name: "Preview").palette(at: 0)))
            .previewLayout(.fixed(width: 300, height: 350))
    }
}
