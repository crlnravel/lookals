//
//  MemoryToolbarBackButton.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct MemoryToolbarBackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button("Back", systemImage: "chevron.left", action: dismiss.callAsFunction)
            .labelStyle(.iconOnly)
            .buttonStyle(CircleToolbarButtonStyle())
    }
}
