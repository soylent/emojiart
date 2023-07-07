//
//  PaletteStore.swift
//  EmojiArt
//
//  Created by soylent on 6/23/23.
//

import SwiftUI

struct Palette: Identifiable, Codable, Hashable {
    var name: String
    var emojis: String
    var id: Int

    fileprivate init(name: String, emojis: String, id: Int) {
        self.name = name
        self.emojis = emojis
        self.id = id
    }
}

class PaletteStore: ObservableObject {
    let name: String

    @Published var palettes = [Palette]() {
        didSet {
            storeInUserDefaults()
        }
    }

    private var userDefaultsKey: String { "PaletteStore:" + name }

    private func storeInUserDefaults() {
        UserDefaults.standard.set(try? JSONEncoder().encode(palettes), forKey: userDefaultsKey)
    }

    private func restoreFromUserDefaults() {
        if let jsonData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedPalettes = try? JSONDecoder().decode([Palette].self, from: jsonData)
        {
            palettes = decodedPalettes
        }
    }

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

    func palette(at index: Int) -> Palette {
        let safeIndex = min(max(index, 0), palettes.count - 1)
        return palettes[safeIndex]
    }

    // MARK: - Intents

    @discardableResult
    func removePalette(at index: Int) -> Int {
        if palettes.count > 1, palettes.indices.contains(index) {
            palettes.remove(at: index)
        }
        return index % palettes.count
    }

    func insertPalette(named name: String, emojis: String? = nil, at index: Int = 0) {
        let unique = (palettes.max(by: { $0.id < $1.id })?.id ?? 0) + 1
        let palette = Palette(name: name, emojis: emojis ?? "", id: unique)
        let safeIndex = min(max(index, 0), palettes.count)
        palettes.insert(palette, at: safeIndex)
    }
}
