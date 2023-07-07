//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by soylent on 6/13/23.
//

import Foundation

struct EmojiArtModel: Codable {
    var background = Background.blank
    var emojis = [Emoji]()

    private var uniqueEmojiId = 0

    struct Emoji: Identifiable, Hashable, Codable {
        let text: String
        /// Horizontal offset from  the center.
        var x: Int
        /// Vertical offset from  the center.
        var y: Int
        var size: Int
        let id: Int

        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }

    init() {}

    init(json: Data) throws {
        self = try JSONDecoder().decode(Self.self, from: json)
    }

    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(json: data)
    }

    func json() throws -> Data {
        try JSONEncoder().encode(self)
    }

    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId))
    }
}
