//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by user on 6/13/23.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument
    @State private var selectedEmojis: Set<EmojiArtModel.Emoji> = []
    @State private var steadyStateZoomScale: CGFloat = 1
    @State private var steadyStatePanOffset: CGSize = .zero
    @GestureState private var gestureZoomScale: CGFloat = 1
    @GestureState private var gesturePanOffset: CGSize = .zero
    @GestureState private var gestureEmojiPanOffset: CGSize = .zero
    private let defaultEmojiFontSize: CGFloat = 40
    private let testEmojis = "🐢🐍🐃🐑🐎🐙🥓🌽🧈🥩🥒🌶🏈🎾🏐⚽️🚘🛻🚨🩼"

    var body: some View {
        VStack(spacing: 0) {
            documentBody
            palette
        }
    }

    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                        .position(convertFromEmojiCoordinates((0, 0), in: geometry))
                )
                .gesture(doubleTapToZoom(in: geometry.size).exclusively(before: singleTapToDeselect()))

                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView()
                } else {
                    ForEach(document.emojis) { emoji in
                        Text(emoji.text)
                            .border(isSelected(emoji) ? DrawingConstants.selectionColor : .clear)
                            .font(.system(size: fontSize(for: emoji)))
                            .scaleEffect(zoomScale(for: emoji))
                            .position(position(for: emoji, in: geometry))
                            .gesture(
                                dragEmojiGesture()
                                    .simultaneously(with: singleTapToSelect(emoji))
                                    .simultaneously(with: removeEmojiGesture(emoji))
                            )
                    }
                }
            }
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGesture()))
        }
    }

    var palette: some View {
        ScrollingEmojiView(emojis: testEmojis)
            .font(.system(size: defaultEmojiFontSize))
    }

    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            document.setBackground(.url(url.imageURL))
        }
        if !found {
            found = providers.loadFirstObject(ofType: UIImage.self) { image in
                if let data = image.jpegData(compressionQuality: 1.0) {
                    document.setBackground(.imageData(data))
                }
            }
        }
        if !found {
            found = providers.loadFirstObject(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(at: location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale
                    )
                }
            }
        }
        return found
    }

    private var zoomScale: CGFloat {
        selectedEmojis.isEmpty ? steadyStateZoomScale * gestureZoomScale : steadyStateZoomScale
    }

    private var panOffset: CGSize { steadyStatePanOffset + gesturePanOffset }

    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }

    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        let offset = isSelected(emoji) ? gestureEmojiPanOffset : .zero
        return convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry) + offset * zoomScale
    }

    private func zoomScale(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        isSelected(emoji) || selectedEmojis.isEmpty ? steadyStateZoomScale * gestureZoomScale : steadyStateZoomScale
    }

    private func isSelected(_ emoji: EmojiArtModel.Emoji) -> Bool {
        selectedEmojis.index(matching: emoji) != nil
    }

    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }

    private func convertToEmojiCoordinates(at location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let x = (location.x - panOffset.width - center.x) / zoomScale
        let y = (location.y - panOffset.height - center.y) / zoomScale
        return (x: Int(x), y: Int(y))
    }

    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }

    private func singleTapToDeselect() -> some Gesture {
        TapGesture().onEnded {
            selectedEmojis.removeAll()
        }
    }

    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStateZoomScale = min(hZoom, vZoom)
            steadyStatePanOffset = .zero
        }
    }

    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureZoomScale, gestureZoomScale, _ in
                gestureZoomScale = latestGestureZoomScale
            }
            .onEnded { finalGestureZoomScale in
                if selectedEmojis.isEmpty {
                    steadyStateZoomScale *= finalGestureZoomScale
                } else {
                    for emoji in selectedEmojis {
                        document.scaleEmoji(emoji, by: finalGestureZoomScale)
                    }
                }
            }
    }

    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }

    private func singleTapToSelect(_ emoji: EmojiArtModel.Emoji) -> some Gesture {
        TapGesture().onEnded {
            selectedEmojis.toggleMembership(of: emoji)
        }
    }

    private func dragEmojiGesture() -> some Gesture {
        DragGesture()
            .updating($gestureEmojiPanOffset) { latestDragGestureValue, gestureEmojiPanOffset, _ in
                gestureEmojiPanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                for emoji in selectedEmojis {
                    document.moveEmoji(emoji, by: finalDragGestureValue.translation)
                }
            }
    }

    private func removeEmojiGesture(_ emoji: EmojiArtModel.Emoji) -> some Gesture {
        LongPressGesture().onEnded { _ in
            document.removeEmoji(emoji)
        }
    }

    private struct DrawingConstants {
        static let selectionColor: Color = .blue
    }
}

struct ScrollingEmojiView: View {
    let emojis: String

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(emojis.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag {
                            NSItemProvider(object: emoji as NSString)
                        }
                }
            }
        }
    }
}

struct EmojiArtDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
    }
}
