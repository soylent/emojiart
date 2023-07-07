//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by soylent on 6/13/23.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument

    @State private var selectedEmojis: Set<EmojiArtModel.Emoji> = []
    @State private var steadyStateZoomScale: CGFloat = 1
    @State private var steadyStatePanOffset: CGSize = .zero
    @State private var alertToShow: IdentifiableAlert?

    @GestureState private var gestureZoomScale: CGFloat = 1
    @GestureState private var gesturePanOffset: CGSize = .zero
    @GestureState private var gestureEmojiPanOffset: (emoji: EmojiArtModel.Emoji?, offset: CGSize) = (nil, .zero)

    private let defaultEmojiFontSize: CGFloat = 38

    var body: some View {
        VStack(spacing: 0) {
            documentBody
            PaletteChooser(emojiFontSize: defaultEmojiFontSize)
                .padding(.horizontal)
        }
    }

    var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                drawBackground(in: geometry)

                if document.backgroundImageFetchStatus == .fetching {
                    ProgressView()
                } else {
                    drawEmojis(in: geometry)
                }
            }
            .clipped()
            .onDrop(of: [.plainText, .url, .image], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
            .gesture(panGesture().simultaneously(with: zoomGesture()))
            .alert(item: $alertToShow) { alertToShow in
                alertToShow.alert()
            }
            .onChange(of: document.backgroundImageFetchStatus) { status in
                switch status {
                case let .failed(url):
                    showBackgroundImageFetchFailedAlert(url)
                default:
                    break
                }
            }
            .onReceive(document.$backgroundImage) { image in
                zoomToFit(image, in: geometry.size)
            }
        }
    }

    private func drawBackground(in geometry: GeometryProxy) -> some View {
        Color.white.overlay(
            OptionalImage(uiImage: document.backgroundImage)
                .scaleEffect(zoomScale)
                .position(convertFromEmojiCoordinates((0, 0), in: geometry))
        )
        .gesture(doubleTapToZoom(in: geometry.size).exclusively(before: singleTapToDeselect()))

    }

    private func drawEmojis(in geometry: GeometryProxy) -> some View {
        ForEach(document.emojis) { emoji in
            Text(emoji.text)
                .border(isSelected(emoji) ? DrawingConstants.selectionColor : .clear)
                .font(.system(size: fontSize(for: emoji)))
                .scaleEffect(zoomScale(for: emoji))
                .position(position(for: emoji, in: geometry))
                .gesture(
                    dragEmojiGesture(emoji)
                        .simultaneously(with: singleTapToSelect(emoji))
                        .simultaneously(with: removeEmojiGesture(emoji))
                )
        }

    }

    private func showBackgroundImageFetchFailedAlert(_ url: URL) {
        alertToShow = IdentifiableAlert(id: "fetch failed: " + url.absoluteString) {
            Alert(
                title: Text("Background Image Fetch"),
                message: Text("Couldn't load image from \(url)"),
                dismissButton: .default(Text("OK"))
            )
        }
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
        let offset = isSelected(emoji) || (selectedEmojis.isEmpty && gestureEmojiPanOffset.emoji == emoji) ? gestureEmojiPanOffset.offset : .zero
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

    private func dragEmojiGesture(_ emoji: EmojiArtModel.Emoji) -> some Gesture {
        DragGesture()
            .updating($gestureEmojiPanOffset) { latestDragGestureValue, gestureEmojiPanOffset, _ in
                gestureEmojiPanOffset = (emoji: emoji, offset: latestDragGestureValue.translation / zoomScale)
            }
            .onEnded { finalDragGestureValue in
                let emojisToMove = selectedEmojis.isEmpty ? [emoji] : selectedEmojis
                for emoji in emojisToMove {
                    document.moveEmoji(emoji, by: finalDragGestureValue.translation / zoomScale)
                }
            }
    }

    private func removeEmojiGesture(_ emoji: EmojiArtModel.Emoji) -> some Gesture {
        LongPressGesture().onEnded { _ in
            document.removeEmoji(emoji)
            selectedEmojis.remove(emoji)
        }
    }

    private enum DrawingConstants {
        static let selectionColor: Color = .blue
    }
}

struct EmojiArtDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
            .environmentObject(PaletteStore(name: "Preview"))
    }
}
