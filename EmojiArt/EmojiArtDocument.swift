//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by user on 6/13/23.
//

import Foundation

class EmojiArtDocument: ObservableObject {
    @Published private(set) var emojiArt: EmojiArtModel

    init() {
        emojiArt = EmojiArtModel()
    }

    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    var background: EmojiArtModel.Background { emojiArt.background }

    // MARK: - Intents

    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
    }

    func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
        emojiArt.addEmoji(text, at: location, size: size)
    }

    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }

    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
        }
    }
}
