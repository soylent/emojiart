//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by soylent on 6/13/23.
//

import SwiftUI
import Combine

/// A view model for a document.
class EmojiArtDocument: ObservableObject {
    /// The underlying document model.
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
            scheduleAutosave()
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }

    /// The background image.
    @Published var backgroundImage: UIImage?

    /// The current fetch status for the background image.
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle

    enum BackgroundImageFetchStatus: Equatable {
        case idle
        case fetching
        case failed(URL)
    }

    /// Creates an empy document or autoloads the previously saved version if available.
    init() {
        if let url = Autosave.url, let autosavedEmojiArt = try? EmojiArtModel(url: url) {
            emojiArt = autosavedEmojiArt
            fetchBackgroundImageDataIfNecessary()
        } else {
            emojiArt = EmojiArtModel()
        }
    }

    /// The emojis comprising the document.
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }

    /// The background of the document.
    var background: EmojiArtModel.Background { emojiArt.background }

    /// Saves the document to the given `url`.
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

    /// Autosave settings.
    private enum Autosave {
        private static let filename = "Autosaved.emojiart"
        static let coalescingInterval = 5.0
        static var url: URL? {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            return documentDirectory?.appendingPathComponent(filename)
        }
    }

    /// Saves the document to a predefined location.
    private func autosave() {
        if let url = Autosave.url {
            save(to: url)
        }
    }

    private var autosaveTimer: Timer?

    /// Schedules a new autosave cancelling any existing autosaves.
    private func scheduleAutosave() {
        autosaveTimer?.invalidate()
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: Autosave.coalescingInterval, repeats: false) { _ in
            self.autosave()
        }
    }

    /// Sets the `backgrounImage` property based on the `background` setting.
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

    private var backgroundImagefetchCancellable: AnyCancellable?

    /// Loads the background image data from the given `url`.
    private func fetchBackgroundImageData(from url: URL) {
        backgroundImageFetchStatus = .fetching
        backgroundImagefetchCancellable?.cancel()
        let session = URLSession.shared
        let publisher = session.dataTaskPublisher(for: url)
            .map { (data, urlResponse) in UIImage(data: data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
        backgroundImagefetchCancellable = publisher.sink { [weak self] image in
            self?.backgroundImage = image
            self?.backgroundImageFetchStatus = image == nil ? .failed(url) : .idle
        }
    }

    // MARK: - Intents

    /// Sets the background to the given value.
    func setBackground(_ background: EmojiArtModel.Background) {
        emojiArt.background = background
    }

    /// Adds an emoji of the given `size` at the specified `location`.
    func addEmoji(_ text: String, at location: (x: Int, y: Int), size: CGFloat) {
        emojiArt.addEmoji(text, at: location, size: Int(size))
    }

    /// Moves the `emoji` by the given `offset`.
    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }

    /// Scales the `emoji` by the given `scale`
    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].size = Int((CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero))
        }
    }

    /// Removes the given `emoji` from the document.
    func removeEmoji(_ emoji: EmojiArtModel.Emoji) {
        emojiArt.emojis.remove(emoji)
    }
}
