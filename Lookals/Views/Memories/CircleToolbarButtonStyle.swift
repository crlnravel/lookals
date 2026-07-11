//
//  CircleToolbarButtonStyle.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct CircleToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: 44, height: 44)
            .background(.regularMaterial, in: Circle())
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}
