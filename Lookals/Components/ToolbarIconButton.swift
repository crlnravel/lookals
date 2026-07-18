//
//  ToolbarIconButton.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import SwiftUI

struct ToolbarIconButton<Background: ShapeStyle>: ToolbarContent {
    let placement: ToolbarItemPlacement
    let systemImage: String
    let accessibilityLabel: String
    let background: Background
    let foreground: Color
    let action: () -> Void

    init(
        placement: ToolbarItemPlacement = .automatic,
        systemImage: String,
        accessibilityLabel: String,
        background: Background = .clear,
        foreground: Color = .primary,
        action: @escaping () -> Void
    ) {
        self.placement = placement
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.background = background
        self.foreground = foreground
        self.action = action
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: placement) {
            ToolbarIconButtonBody(
                systemImage: systemImage,
                accessibilityLabel: accessibilityLabel,
                background: background,
                foreground: foreground,
                action: action
            )
        }
        .sharedBackgroundVisibility(.hidden)
    }
}

private struct ToolbarIconButtonBody<Background: ShapeStyle>: View {
    let systemImage: String
    let accessibilityLabel: String
    let background: Background
    let foreground: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(background)
                    .frame(width: 44, height: 44)

                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(foreground)
            }
            .contentShape(Circle())
        }
        .accessibilityLabel(accessibilityLabel)
        .buttonStyle(.plain)
        .frame(width: 44, height: 44)
        .glassEffect()
    }
}

#Preview("Toolbar Icon Button") {
    NavigationStack {
        Color(.black)
            .navigationTitle("Preview")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarIconButton(
                    systemImage: "chevron.left",
                    accessibilityLabel: "Go back",
                    background: Color.accentColor,
                    foreground: .white,
                    action: {}
                )
            }
            .background(.black)
    }
}
