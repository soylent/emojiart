//
//  PaletteManager.swift
//  EmojiArt
//
//  Created by user on 6/26/23.
//

import SwiftUI

struct PaletteManager: View {
    @EnvironmentObject private var store: PaletteStore

    @Environment(\.isPresented) private var isPresented
    @Environment(\.dismiss) private var dismiss

    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationView {
            List {
                ForEach(store.palettes) { palette in
                    NavigationLink {
                        PaletteEditor(palette: $store.palettes[palette])
                    } label: {
                        VStack(alignment: .leading) {
                            Text(palette.name)
                        }
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
            .toolbar {
                ToolbarItem { EditButton() }
                ToolbarItem(placement: .navigationBarLeading) {
                    if isPresented, UIDevice.current.userInterfaceIdiom != .pad {
                        Button("Close") { dismiss() }
                    }
                }
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
