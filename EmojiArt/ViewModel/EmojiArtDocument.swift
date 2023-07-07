//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by soylent on 6/13/23.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
            scheduleAutosave()
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }

    @Published var backgroundImage: UIImage?
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle

    enum BackgroundImageFetchStatus: Equatable {
        case idle
        case fetching
        case failed(URL)
    }

    init() {
        if let url = Autosave.url, let autosavedEmojiArt = try? EmojiArtModel(url: url) {
            emojiArt = autosavedEmojiArt
            fetchBackgroundImageDataIfNecessary()
        } else {
            emojiArt = EmojiArtModel()
        }
    }

    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    var background: EmojiArtModel.Background { emojiArt.background }

    private func save(to url: URL) {
        let thisfunction = "\(String(describing: self)).\(#function)"
        do {
            let data = try emojiArt.json()
            print("\(thisfunction) json = \(String(data: data, encoding: .utf8) ?? "nil")")
            try data.write(to: url)
            print("\(thisfunction) success!")
        } catch let encodingError where encodingError is EncodingError {
            print("\(thisfunction) could not encode EmojiArt as JSON because \(encodingError.localizedDescription)")
        } catch {
            print("\(thisfunction) error = \(error)")
        }
    }

    private enum Autosave {
        private static let filename = "Autosaved.emojiart"
        static let coalescingInterval = 5.0
        static var url: URL? {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            return documentDirectory?.appendingPathComponent(filename)
        }
    }

    private func autosave() {
        if let url = Autosave.url {
            save(to: url)
        }
    }

    private var autosaveTimer: Timer?

    private func scheduleAutosave() {
        autosaveTimer?.invalidate()
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: Autosave.coalescingInterval, repeats: false) { _ in
            self.autosave()
        }
    }

    private func fetchBackgroundImageDataIfNecessary() {
        backgroundImage = nil
        switch background {
        case let .url(url):
            fetchBackgroundImageData(from: url)
        case let .imageData(data):
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }

    private func fetchBackgroundImageData(from url: URL) {
        backgroundImageFetchStatus = .fetching

        DispatchQueue.global(qos: .userInitiated).async {
            guard let data = try? Data(contentsOf: url) else { return }

            DispatchQueue.main.async { [weak self] in
                guard self?.background == EmojiArtModel.Background.url(url) else { return }

                self?.backgroundImageFetchStatus = .idle
                self?.backgroundImage = UIImage(data: data)
                if self?.backgroundImage == nil {
                    self?.backgroundImageFetchStatus = .failed(url)
                }
            }
        }
    }

    // MARK: - Intents

    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
    }

    func addEmoji(_ text: String, at location: (x: Int, y: Int), size: CGFloat) {
        emojiArt.addEmoji(text, at: location, size: Int(size))
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

    func removeEmoji(_ emoji: EmojiArtModel.Emoji) {
        emojiArt.emojis.remove(emoji)
    }
}
