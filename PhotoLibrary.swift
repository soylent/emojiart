//
//  PhotoLibrary.swift
//  EmojiArt
//
//  Created by soylent on 7/14/23.
//

import SwiftUI
import PhotosUI

/// Photo library image picker.
struct PhotoLibrary: UIViewControllerRepresentable {
    /// Whether the photo library is available.
    static let isAvailable = true

    /// Callback to handle a picked image.
    var handlePickedImage: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // Nothing to do.
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(handlePickedImage: handlePickedImage)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private var handlePickedImage: (UIImage?) -> Void

        init(handlePickedImage: @escaping (UIImage?) -> Void) {
            self.handlePickedImage = handlePickedImage
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let found = results.map { $0.itemProvider }.loadObjects(ofType: UIImage.self) { [weak self] image in
                self?.handlePickedImage(image)
            }
            if !found {
                handlePickedImage(nil)
            }
        }
    }
}
