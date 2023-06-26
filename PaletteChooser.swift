//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by user on 6/25/23.
//

import SwiftUI

struct PaletteChooser: View {
    var emojiFontSize: CGFloat = 40
    var emojiFont: Font { .system(size: emojiFontSize) }

    @EnvironmentObject var store: PaletteStore

    var body: some View {
        let palette = store.palette(at: 0)
        HStack {
            Text(palette.name)
            ScrollingEmojiView(emojis: palette.emojis)
                .font(emojiFont)
        }
    }
}

struct ScrollingEmojiView: View {
    let emojis: String

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.withNoRepeatedCharacters.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag {
                            NSItemProvider(object: emoji as NSString)
                        }
                }
            }
        }
    }
}

struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser()
    }
}
