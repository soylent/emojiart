//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by soylent on 6/13/23.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

extension UTType {
    static let emojiart = UTType(exportedAs: "edu.stanford.cs193p.kpa.emojiart")
}

/// A view model for a document.
class EmojiArtDocument: ReferenceFileDocument {
    static var readableContentTypes = [UTType.emojiart]
    static var writableContentTypes = [UTType.emojiart]

    func snapshot(contentType: UTType) throws -> Data {
        try emojiArt.json()
    }

    func fileWrapper(snapshot: Data, configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: snapshot)
    }

    required init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            emojiArt = try EmojiArtModel(json: data)
            fetchBackgroundImageDataIfNecessary()
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    /// The underlying document model.
    @Published private(set) var emojiArt: EmojiArtModel {
        didSet {
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
        emojiArt = EmojiArtModel()
    }

    /// The emojis comprising the document.
    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }

    /// The background of the document.
    var background: EmojiArtModel.Background { emojiArt.background }

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
