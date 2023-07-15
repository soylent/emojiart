//
//  UtilityViews.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/26/21.
//  Copyright © 2021 Stanford University. All rights reserved.
//

import SwiftUI

// syntactic sure to be able to pass an optional UIImage to Image
// (normally it would only take a non-optional UIImage)

struct OptionalImage: View {
    var uiImage: UIImage?

    var body: some View {
        if uiImage != nil {
            Image(uiImage: uiImage!)
        }
    }
}

// syntactic sugar
// lots of times we want a simple button
// with just text or a label or a systemImage
// but we want the action it performs to be animated
// (i.e. withAnimation)
// this just makes it easy to create such a button
// and thus cleans up our code

struct AnimatedActionButton: View {
    var title: String? = nil
    var systemImage: String? = nil
    let action: () -> Void

    var body: some View {
        Button {
            withAnimation {
                action()
            }
        } label: {
            if title != nil, systemImage != nil {
                Label(title!, systemImage: systemImage!)
            } else if title != nil {
                Text(title!)
            } else if systemImage != nil {
                Image(systemName: systemImage!)
            }
        }
    }
}

// simple struct to make it easier to show configurable Alerts
// just an Identifiable struct that can create an Alert on demand
// use .alert(item: $alertToShow) { theIdentifiableAlert in ... }
// where alertToShow is a Binding<IdentifiableAlert>?
// then any time you want to show an alert
// just set alertToShow = IdentifiableAlert(id: "my alert") { Alert(title: ...) }
// of course, the string identifier has to be unique for all your different kinds of alerts

struct IdentifiableAlert: Identifiable {
    var id: String
    var alert: () -> Alert

    init(title: String, message: String) {
        id = title + message
        alert = { Alert(title: Text(title), message: Text(message), dismissButton: .default(Text("OK"))) }
    }

    init(id: String, alert: @escaping () -> Alert) {
        self.id = id
        self.alert = alert
    }
}

extension View {
    @ViewBuilder
    func wrappedInNavigationStackToMakeDismissable(_ dismiss: (() -> Void)?) -> some View {
        if let dismiss, UIDevice.current.userInterfaceIdiom != .pad {
            NavigationStack {
                self
                    .navigationBarTitleDisplayMode(.inline)
                    .dismissable(dismiss)
            }
        } else {
            self
        }
    }

    @ViewBuilder
    func dismissable(_ dismiss: (() -> Void)?) -> some View {
        if let dismiss, UIDevice.current.userInterfaceIdiom != .pad {
            self.toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        } else {
            self
        }
    }
}

extension View {
    func compactableToolbar<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        self.toolbar {
            content().modifier(CompactableIntoContextMenu())
        }
    }
}

struct CompactableIntoContextMenu: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        if horizontalSizeClass == .compact {
            Menu { content } label: { Image(systemName: "ellipsis.circle") }
        } else {
            content
        }
    }
}
