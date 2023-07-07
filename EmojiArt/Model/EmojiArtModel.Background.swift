//
//  EmojiArtModel.Background.swift
//  EmojiArt
//
//  Created by soylent on 6/13/23.
//

import Foundation

extension EmojiArtModel {
    enum Background: Equatable, Codable {
        case blank
        case url(URL)
        case imageData(Data)

        var url: URL? {
            switch self {
            case let .url(url):
                return url
            default:
                return nil
            }
        }

        var imageData: Data? {
            switch self {
            case let .imageData(data):
                return data
            default:
                return nil
            }
        }

        enum CodingKeys: String, CodingKey {
            case url = "theURL"
            case imageData
        }

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
