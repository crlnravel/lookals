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
    let action: () -> Void

    init(
        systemImage: String,
        accessibilityLabel: String,
        background: Background = .clear,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.accessibilityLabel = accessibilityLabel
        self.background = background
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .accessibilityLabel(accessibilityLabel)
    }
}

#Preview("Toolbar Icon Button") {
    NavigationStack {
        Color(.systemBackground)
            .navigationTitle("Preview")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ToolbarIconButton(
                        systemImage: "chevron.left",
                        accessibilityLabel: "Go back",
                        action: {}
                    )
                }
            }
    }
}
