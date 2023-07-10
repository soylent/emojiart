//
//  EmojiArtModel.swift
//  EmojiArt
//
//  Created by soylent on 6/13/23.
//

import Foundation

/// The main model that represents a document consisting of a background image and emojis on top of it.
struct EmojiArtModel: Codable {
    /// The background of the document.
    var background = Background.blank

    /// The emojis comprising the document.
    var emojis = [Emoji]()

    /// The counter used to generate emoji ids.
    private var uniqueEmojiId = 0

    /// The emoji model.
    struct Emoji: Identifiable, Hashable, Codable {
        /// The emoji character.
        let text: String

        /// Horizontal offset from  the center.
        var x: Int

        /// Vertical offset from  the center.
        var y: Int

        /// The font size.
        var size: Int

        /// The identifier.
        let id: Int

        /// Creates a new emoji with the given parameters.
        fileprivate init(text: String, x: Int, y: Int, size: Int, id: Int) {
            self.text = text
            self.x = x
            self.y = y
            self.size = size
            self.id = id
        }
    }

    /// Creates a empty art document.
    init() {}

    /// Creates a document from the given `json` data.
    init(json: Data) throws {
        self = try JSONDecoder().decode(Self.self, from: json)
    }

    /// Creates a document by loading its data from the given `url`.
    init(url: URL) throws {
        let data = try Data(contentsOf: url)
        try self.init(json: data)
    }

    /// Returns the JSON representation of the document.
    func json() throws -> Data {
        try JSONEncoder().encode(self)
    }

    /// Adds an emoji of the given `size` at the specified `location`.
    mutating func addEmoji(_ text: String, at location: (x: Int, y: Int), size: Int) {
        uniqueEmojiId += 1
        emojis.append(Emoji(text: text, x: location.x, y: location.y, size: size, id: uniqueEmojiId))
    }
}
