//
//  PaletteEditor.swift
//  EmojiArt
//
//  Created by user on 6/25/23.
//

import SwiftUI

struct PaletteEditor: View {
    @Binding var palette: Palette

    var body: some View {
        Form {
            TextField("Name", text: $palette.name)
        }
        .frame(minWidth: 300, minHeight: 350)
    }
}

struct PaletteEditor_Previews: PreviewProvider {
    static var previews: some View {
        PaletteEditor(palette: .constant(PaletteStore(name: "Preview").palette(at: 0)))
            .previewLayout(.fixed(width: 300, height: 350))
    }
}
