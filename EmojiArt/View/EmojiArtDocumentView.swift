//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by soylent on 6/13/23.
//

import SwiftUI

/// The main document view.
struct EmojiArtDocumentView: View {
    /// A reference to the document view model.
    @ObservedObject var document: EmojiArtDocument

    /// A set of the currently selected emojis.
    @State private var selectedEmojis: Set<EmojiArtModel.Emoji> = []

    /// Whether to show the specified alert.
    @State private var alertToShow: IdentifiableAlert?

    /// Whether to show a background image picker.
    @State private var backgroundPicker: BackgroundPickerType?

    /// Whether to autoscale the background image.
    @State var autozoom = false

    /// The overall zoom scale.
    @SceneStorage("EmojiArtDocumentView.steadyStateZoomScale")
    private var steadyStateZoomScale: CGFloat = 1

    /// The overall pan offset.
    @SceneStorage("EmojiArtDocumentView.steadyStatePanOffset")
    private var steadyStatePanOffset: CGSize = .zero

    /// Additional zoom scale while pinching.
    @GestureState private var gestureZoomScale: CGFloat = 1

    /// Additional pan offset while dragging.
    @GestureState private var gesturePanOffset: CGSize = .zero

    /// Additional pan offset while draggin an emoji.
    @GestureState private var gestureEmojiPanOffset: (emoji: EmojiArtModel.Emoji?, offset: CGSize) = (nil, .zero)

    /// The default emoji font size.
    @ScaledMetric private var defaultEmojiFontSize: CGFloat = 38

    /// The undo manager.
    @Environment(\.undoManager) private var undoManager

    /// The view body.
    var body: some View {
        VStack(spacing: 0) {
            documentBody
            PaletteChooser(emojiFontSize: defaultEmojiFontSize)
                .padding(.horizontal)
        }
    }

    /// The document view.
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
            .onDrop(of: [.utf8PlainText, .url, .image], isTargeted: nil) { providers, location in
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
                if autozoom {
                    zoomToFit(image, in: geometry.size)
                }
            }
            .compactableToolbar {
                AnimatedActionButton(title: "Paste Background", systemImage: "doc.on.clipboard") {
                    pasteBackground()
                }
                if Camera.isAvailable {
                    AnimatedActionButton(title: "Take Photo", systemImage: "camera") {
                        backgroundPicker = .camera
                    }
                }
                if PhotoLibrary.isAvailable {
                    AnimatedActionButton(title: "Search Photos", systemImage: "photo") {
                        backgroundPicker = .library
                    }
                }
                #if os(iOS)
                if let undoManager {
                    if undoManager.canUndo {
                        AnimatedActionButton(title: undoManager.undoActionName, systemImage: "arrow.uturn.backward") {
                            undoManager.undo()
                        }
                    }
                    if undoManager.canRedo {
                        AnimatedActionButton(title: undoManager.undoActionName, systemImage: "arrow.uturn.forward") {
                            undoManager.redo()
                        }
                    }
                }
                #endif
            }
            .sheet(item: $backgroundPicker) { picker in
                switch picker {
                case .camera:
                    Camera(handlePickedImage: { image in handlePickedBackgroundImage(image) })
                case .library:
                    PhotoLibrary(handlePickedImage: { image in handlePickedBackgroundImage(image) })
                }
            }
        }
    }

    private enum BackgroundPickerType: Identifiable {
        case camera
        case library

        var id: Self { self }
    }

    private func handlePickedBackgroundImage(_ image: UIImage?) {
        autozoom = true
        if let imageData = image?.imageData {
            document.setBackground(.imageData(imageData), with: undoManager)
        }
        backgroundPicker = nil
    }

    private func pasteBackground() {
        autozoom = true
        if let imageData = Pasteboard.imageData {
            document.setBackground(.imageData(imageData), with: undoManager)
        } else if let url = Pasteboard.imageURL {
            document.setBackground(.url(url), with: undoManager)
        } else {
            alertToShow = IdentifiableAlert(title: "Paste Background", message: "There is no image currently on the pasteboard." )
        }
    }

    /// Returns the document background that fits within the given `geometry`.
    @ViewBuilder
    private func drawBackground(in geometry: GeometryProxy) -> some View {
        Color.white
        OptionalImage(uiImage: document.backgroundImage)
            .scaleEffect(zoomScale)
            .position(convertFromEmojiCoordinates((0, 0), in: geometry))
        .gesture(doubleTapToZoom(in: geometry.size).exclusively(before: singleTapToDeselect()))
    }

    /// Returns the document emojis positioned withing the given `geometry`.
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

    /// Shows an alert in case of a background image fetch failure.
    private func showBackgroundImageFetchFailedAlert(_ url: URL) {
        alertToShow = IdentifiableAlert(title: "Background Image Fetch", message: "Couldn't load image from \(url)")
    }

    /// Handles drag & drop for images and emojis.
    private func drop(providers: [NSItemProvider], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            autozoom = true
            document.setBackground(.url(url.imageURL), with: undoManager)
        }
        #if os(iOS)
        if !found {
            found = providers.loadFirstObject(ofType: UIImage.self) { image in
                if let data = image.imageData {
                    autozoom = true
                    document.setBackground(.imageData(data), with: undoManager)
                }
            }
        }
        #endif
        if !found {
            found = providers.loadFirstObject(ofType: String.self) { string in
                if let emoji = string.first, emoji.isEmoji {
                    document.addEmoji(
                        String(emoji),
                        at: convertToEmojiCoordinates(at: location, in: geometry),
                        size: defaultEmojiFontSize / zoomScale,
                        with: undoManager
                    )
                }
            }
        }
        return found
    }

    /// The effective zoom scale.
    private var zoomScale: CGFloat {
        selectedEmojis.isEmpty ? steadyStateZoomScale * gestureZoomScale : steadyStateZoomScale
    }

    /// The effective pan offset.
    private var panOffset: CGSize { steadyStatePanOffset + gesturePanOffset }

    /// Returns the font size for the given `emoji`.
    private func fontSize(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        CGFloat(emoji.size)
    }

    /// Returns the position for the given emoji within the specified `geometry`.
    private func position(for emoji: EmojiArtModel.Emoji, in geometry: GeometryProxy) -> CGPoint {
        let offset = isSelected(emoji) || (selectedEmojis.isEmpty && gestureEmojiPanOffset.emoji == emoji) ? gestureEmojiPanOffset.offset : .zero
        return convertFromEmojiCoordinates((emoji.x, emoji.y), in: geometry) + offset * zoomScale
    }

    /// Returns the effective zoom scale for the given emoji.
    private func zoomScale(for emoji: EmojiArtModel.Emoji) -> CGFloat {
        isSelected(emoji) || selectedEmojis.isEmpty ? steadyStateZoomScale * gestureZoomScale : steadyStateZoomScale
    }

    /// Returns whether the given `emoji` is currently selected.
    private func isSelected(_ emoji: EmojiArtModel.Emoji) -> Bool {
        selectedEmojis.index(matching: emoji) != nil
    }

    /// Converts the given center offset `location` to actual screen location.
    private func convertFromEmojiCoordinates(_ location: (x: Int, y: Int), in geometry: GeometryProxy) -> CGPoint {
        let center = geometry.frame(in: .local).center
        return CGPoint(
            x: center.x + CGFloat(location.x) * zoomScale + panOffset.width,
            y: center.y + CGFloat(location.y) * zoomScale + panOffset.height
        )
    }

    /// Converts the given screen `location` to its center offset counterpart.
    private func convertToEmojiCoordinates(at location: CGPoint, in geometry: GeometryProxy) -> (x: Int, y: Int) {
        let center = geometry.frame(in: .local).center
        let x = (location.x - panOffset.width - center.x) / zoomScale
        let y = (location.y - panOffset.height - center.y) / zoomScale
        return (x: Int(x), y: Int(y))
    }

    /// Returns a gesture to fit the background within the given `size` on double tap.
    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }

    /// Returns a gesture to remove the currently selected emojis on single tap.
    private func singleTapToDeselect() -> some Gesture {
        TapGesture().onEnded {
            selectedEmojis.removeAll()
        }
    }

    /// Changes the overall zoom to fit the given `image` within the `size`.
    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image, image.size.width > 0, image.size.height > 0, size.width > 0, size.height > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            steadyStateZoomScale = min(hZoom, vZoom)
            steadyStatePanOffset = .zero
        }
    }

    /// Returns a gesture to scale the document while pinching.
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
                        document.scaleEmoji(emoji, by: finalGestureZoomScale, with: undoManager)
                    }
                }
            }
    }

    /// Returns a gesture to pan the document while dragging.
    private func panGesture() -> some Gesture {
        DragGesture()
            .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, _ in
                gesturePanOffset = latestDragGestureValue.translation / zoomScale
            }
            .onEnded { finalDragGestureValue in
                steadyStatePanOffset = steadyStatePanOffset + (finalDragGestureValue.translation / zoomScale)
            }
    }

    /// Returns a gesture to select or unselect the given `emoji` on single tap.
    private func singleTapToSelect(_ emoji: EmojiArtModel.Emoji) -> some Gesture {
        TapGesture().onEnded {
            selectedEmojis.toggleMembership(of: emoji)
        }
    }

    /// Returns a gesture to move the given `emoji` while dragging.
    private func dragEmojiGesture(_ emoji: EmojiArtModel.Emoji) -> some Gesture {
        DragGesture()
            .updating($gestureEmojiPanOffset) { latestDragGestureValue, gestureEmojiPanOffset, _ in
                gestureEmojiPanOffset = (emoji: emoji, offset: latestDragGestureValue.translation / zoomScale)
            }
            .onEnded { finalDragGestureValue in
                let emojisToMove = selectedEmojis.isEmpty ? [emoji] : selectedEmojis
                for emoji in emojisToMove {
                    document.moveEmoji(emoji, by: finalDragGestureValue.translation / zoomScale,
                                       with: undoManager)
                }
            }
    }

    /// Returns a gesture to remove the given `emoji` on a long press.
    private func removeEmojiGesture(_ emoji: EmojiArtModel.Emoji) -> some Gesture {
        LongPressGesture().onEnded { _ in
            document.removeEmoji(emoji, with: undoManager)
            selectedEmojis.remove(emoji)
        }
    }

    /// Constants related to the view appearance.
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
