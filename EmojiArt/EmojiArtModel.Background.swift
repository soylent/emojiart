//
//  EmojiArtModel.Background.swift
//  EmojiArt
//
//  Created by user on 6/13/23.
//

import Foundation

extension EmojiArtModel {
    enum Background: Equatable {
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
    }
}
