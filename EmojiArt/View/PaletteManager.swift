//
//  PaletteManager.swift
//  EmojiArt
//
//  Created by soylent on 6/26/23.
//

import SwiftUI

/// Palette list.
struct PaletteManager: View {
    /// A reference to the palette store view model.
    @EnvironmentObject private var store: PaletteStore

    /// Whether this view is currently presented.
    @Environment(\.isPresented) private var isPresented

    /// Dismises this view.
    @Environment(\.dismiss) private var dismiss

    /// Whether the palette list is editable.
    @State private var editMode: EditMode = .inactive

    /// The view body.
    var body: some View {
        // NOTE: Due to a bug in SwiftUI, animations are not working in NavigationStack.
        // https://developer.apple.com/forums/thread/728132
        NavigationView {
            List {
                ForEach(store.palettes) { palette in
                    NavigationLink {
                        PaletteEditor(palette: $store.palettes[palette])
                    } label: {
                        Text(palette.name)
                    }
                }
                .onDelete { indexSet in
                    store.palettes.remove(atOffsets: indexSet)
                }
                .onMove { indexSet, newOffset in
                    store.palettes.move(fromOffsets: indexSet, toOffset: newOffset)
                }
            }
            .navigationTitle("Manage Palettes")
            .navigationBarTitleDisplayMode(.inline)
            .dismissable { dismiss() }
            .toolbar {
                EditButton()
            }
            .environment(\.editMode, $editMode)
        }
    }
}

struct PaletteManager_Previews: PreviewProvider {
    static var previews: some View {
        PaletteManager()
            .environmentObject(PaletteStore(name: "Preview"))
    }
}
