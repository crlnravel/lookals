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
        Button(action: dismiss.callAsFunction) {
            Image(systemName: "chevron.left")
                .fontWeight(.bold)
                .foregroundColor(.black)
        }
        .accessibilityLabel("Back")
        .buttonStyle(.plain)
    }
}
