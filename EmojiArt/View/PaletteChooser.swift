//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by soylent on 6/25/23.
//

import SwiftUI

/// Palette selection menu.
struct PaletteChooser: View {
    /// The emoji size.
    var emojiFontSize: CGFloat = 40

    /// The emoji font.
    var emojiFont: Font { .system(size: emojiFontSize) }

    /// A reference to the palette store view model.
    @EnvironmentObject var store: PaletteStore

    /// The index of the currently selected palette.
    @SceneStorage("PaletteChooser.chosedPaletteIndex")
    private var chosenPaletteIndex = 0

    /// Whether to show the editor for the specified palette.
    @State private var paletteToEdit: Palette?

    /// Whether to show the palette manager.
    @State private var managing = false

    /// The view body.
    var body: some View {
        HStack {
            paletteControlButton
            body(for: store.palette(at: chosenPaletteIndex))
        }
        .clipped()
    }

    /// The button to select the next palette.
    private var paletteControlButton: some View {
        Button {
            withAnimation {
                chosenPaletteIndex = (chosenPaletteIndex + 1) % store.palettes.count
            }
        } label: {
            Image(systemName: "paintpalette")
        }
        .font(emojiFont)
        .contextMenu { contextMenu }
    }

    /// The context menu for the paletee control button.
    @ViewBuilder
    private var contextMenu: some View {
        AnimatedActionButton(title: "Edit", systemImage: "square.and.pencil") {
            paletteToEdit = store.palette(at: chosenPaletteIndex)
        }
        AnimatedActionButton(title: "New", systemImage: "plus") {
            store.insertPalette(named: "New", emojis: "", at: chosenPaletteIndex)
            paletteToEdit = store.palette(at: chosenPaletteIndex)
        }
        AnimatedActionButton(title: "Delete", systemImage: "trash") {
            chosenPaletteIndex = store.removePalette(at: chosenPaletteIndex)
        }
        AnimatedActionButton(title: "Manager", systemImage: "slider.horizontal.3") {
            managing = true
        }
        gotoMenu
    }

    /// Palette switching menu.
    private var gotoMenu: some View {
        Menu {
            ForEach(store.palettes) { palette in
                AnimatedActionButton(title: palette.name) {
                    if let index = store.palettes.index(matching: palette) {
                        chosenPaletteIndex = index
                    }
                }
            }
        } label: {
            Label("Go To", systemImage: "arrow.triangle.swap")
        }
    }

    /// Returns a view representing the given `palette`.
    private func body(for palette: Palette) -> some View {
        HStack {
            ScrollingEmojiView(emojis: palette.emojis)
                .font(emojiFont)
        }
        .id(palette.id)
        .transition(rollTransition)
        .popover(item: $paletteToEdit) { palette in
            PaletteEditor(palette: $store.palettes[palette])
        }
        .sheet(isPresented: $managing) {
            PaletteManager()
        }
    }

    private var rollTransition: AnyTransition {
        .asymmetric(insertion: .offset(x: 0, y: emojiFontSize), removal: .offset(x: 0, y: -emojiFontSize))
    }
}

/// A horizontally scrolling row of emojis.
struct ScrollingEmojiView: View {
    let emojis: String

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(emojis.withNoRepeatedCharacters.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .onDrag {
                            NSItemProvider(object: emoji as NSString)
                        }
                }
            }
        }
    }
}

struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser()
            .environmentObject(PaletteStore(name: "Preview"))
    }
}
