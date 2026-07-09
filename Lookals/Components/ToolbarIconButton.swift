//
//  ToolbarIconButton.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import SwiftUI

struct ToolbarIconButton<Background: ShapeStyle>: View {
    let systemImage: String
    let accessibilityLabel: String
    let background: Background
    let foreground: Color
    let action: () -> Void

    init(
        systemImage: String,
        accessibilityLabel: String,
        background: Background = .clear,
        foreground: Color = .primary,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.background = background
        self.foreground = foreground
        self.action = action
    }

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
                ToolbarItem(placement: .automatic) {
                    ToolbarIconButton(
                        systemImage: "chevron.left",
                        accessibilityLabel: "Go back",
                        background: .accent,
                        foreground: .white,
                        action: {}
                    )
                }
                .sharedBackgroundVisibility(.hidden)
            }
            .background(.black)
    }
}
