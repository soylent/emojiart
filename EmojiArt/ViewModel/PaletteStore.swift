//
//  PaletteStore.swift
//  EmojiArt
//
//  Created by soylent on 6/23/23.
//

import SwiftUI

/// Emoji palette.
struct Palette: Identifiable, Codable, Hashable {
    /// The name of the palette.
    var name: String

    /// The emojis comprising the palette.
    var emojis: String

    /// The palette id.
    var id: Int

    /// Creates a new palette with the given parameters.
    fileprivate init(name: String, emojis: String, id: Int) {
        self.name = name
        self.emojis = emojis
        self.id = id
    }
}

/// A collection of palettes.
class PaletteStore: ObservableObject {
    let name: String

    /// The palettes comprising the collection.
    @Published var palettes = [Palette]() {
        didSet {
            storeInUserDefaults()
        }
    }

    private var userDefaultsKey: String { "PaletteStore:" + name }

    /// Saves the palettes to `UserDefaults`.
    private func storeInUserDefaults() {
        UserDefaults.standard.set(try? JSONEncoder().encode(palettes), forKey: userDefaultsKey)
    }

    /// Restores the paletess from `UserDefaults`.
    private func restoreFromUserDefaults() {
        if let jsonData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedPalettes = try? JSONDecoder().decode([Palette].self, from: jsonData)
        {
            palettes = decodedPalettes
        }
    }

    /// Creates a pre-defined palette collection or loads the previously saved version if available.
    init(name: String) {
        self.name = name

        restoreFromUserDefaults()

        if palettes.isEmpty {
            print("Loaded built-in palettes")
            insertPalette(named: "Objects", emojis: "⏰🧭☎️🧲🎈🧽🔫")
            insertPalette(named: "Vehicles", emojis: "🚕🚗🚕🚙🚌🚓🚑🚐🚒🚛🚚🚎")
            insertPalette(named: "Sports", emojis: "🏀🏈⚽️⚾️🏉🎾🥎🎱🥏🪀")
            insertPalette(named: "Food", emojis: "🍎🍊🍏🍐🍌🍋🥭🍓🫐🍅🍆🥥")
            insertPalette(named: "Animals", emojis: "🐹🐻🦊🐯🦁🐷🐮🐵🐼🐨🐻‍❄️")
        } else {
            print("Loaded palettes from UserDefaults: \(palettes)")
        }
    }

    /// Returns the palette at the given `index`.
    func palette(at index: Int) -> Palette {
        let safeIndex = min(max(index, 0), palettes.count - 1)
        return palettes[safeIndex]
    }

    // MARK: - Intents

    /// Removes the palette at the given `index`.
    @discardableResult
    func removePalette(at index: Int) -> Int {
        if palettes.count > 1, palettes.indices.contains(index) {
            palettes.remove(at: index)
        }
        return index % palettes.count
    }

    /// Adds a palette with the specified parameters at the given `index`.
    func insertPalette(named name: String, emojis: String? = nil, at index: Int = 0) {
        let unique = (palettes.max(by: { $0.id < $1.id })?.id ?? 0) + 1
        let palette = Palette(name: name, emojis: emojis ?? "", id: unique)
        let safeIndex = min(max(index, 0), palettes.count)
        palettes.insert(palette, at: safeIndex)
    }
}
