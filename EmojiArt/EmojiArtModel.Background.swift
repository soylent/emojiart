//
//  EmojiArtModel.Background.swift
//  EmojiArt
//
//  Created by user on 6/13/23.
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

        enum UrlCodingKeys: CodingKey {
            case _0
        }

        enum ImageDataCodingKeys: CodingKey {
            case _0
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
            case .url(let url):
                try container.encode(url, forKey: .url)
            case .imageData(let imageData):
                try container.encode(imageData, forKey: .imageData)
            case .blank:
                break
            }
        }
    }
}
