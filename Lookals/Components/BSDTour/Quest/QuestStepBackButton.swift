//
//  QuestStepBackButton.swift
//  Lookals
//
//  Created by Codex on 10/07/26.
//

import SwiftUI

struct QuestStepBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Previous", systemImage: "chevron.left")
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemBackground), in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Previous section")
    }
}

#Preview {
    QuestStepBackButton {}
        .padding()
}
