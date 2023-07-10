//
//  EmojiArtModel.Background.swift
//  EmojiArt
//
//  Created by soylent on 6/13/23.
//

import Foundation

extension EmojiArtModel {
    /// The background model.
    enum Background: Equatable, Codable {
        case blank
        case url(URL)
        case imageData(Data)

        /// The background image URL.
        var url: URL? {
            switch self {
            case let .url(url):
                return url
            default:
                return nil
            }
        }

        /// The background image data.
        var imageData: Data? {
            switch self {
            case let .imageData(data):
                return data
            default:
                return nil
            }
        }

        /// Coding settings.
        enum CodingKeys: String, CodingKey {
            case url = "theURL"
            case imageData
        }

        /// Creates a new instance by deserializing it using the given `decoder`.
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let url = try? container.decode(URL.self, forKey: .url) {
                self = .url(url)
            } else if let imageData = try? container.decode(Data.self, forKey: .imageData) {
                self = .imageData(imageData)
            } else {
                self = .blank
            }
        }

        /// Encodes itself using the given `encoder`.
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case let .url(url):
                try container.encode(url, forKey: .url)
            case let .imageData(imageData):
                try container.encode(imageData, forKey: .imageData)
            case .blank:
                break
            }
        }
    }
}
