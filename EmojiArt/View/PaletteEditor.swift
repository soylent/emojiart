//
//  PaletteEditor.swift
//  EmojiArt
//
//  Created by soylent on 6/25/23.
//

import SwiftUI

/// Palette edit form.
struct PaletteEditor: View {
    /// The palette being edited.
    @Binding var palette: Palette

    /// Emojis to add to the palette.
    @State private var emojisToAdd = ""

    /// Palette edit form view.
    var body: some View {
        Form {
            nameSection
            addEmojiSection
            removeEmojiSection
        }
        .frame(minWidth: 300, minHeight: 350)
        .navigationTitle("Edit \(palette.name)")
    }

    /// The palette name field.
    private var nameSection: some View {
        Section(header: Text("Name")) {
            TextField("Name", text: $palette.name)
        }
    }

    /// A field for adding emojis to the palette.
    private var addEmojiSection: some View {
        Section(header: Text("Add Emojis")) {
            TextField("", text: $emojisToAdd)
                .onChange(of: emojisToAdd) { emojis in
                    withAnimation {
                        palette.emojis = (emojis + palette.emojis)
                            .filter(\.isEmoji)
                            .withNoRepeatedCharacters
                    }
                }
        }
    }

    /// An emoji grid for removing emojis from the palette.
    private var removeEmojiSection: some View {
        Section(header: Text("Remove Emoji")) {
            let emojis = palette.emojis.withNoRepeatedCharacters.map { String($0) }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 20))]) {
                ForEach(emojis, id: \.self) { emoji in
                    Text(emoji)
                        .onTapGesture {
                            withAnimation {
                                palette.emojis.removeAll { String($0) == emoji }
                            }
                        }
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
