//
//  PrimaryButton.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import SwiftUI

struct PrimaryButton: View {
    let title: String
    let accessibilityLabel: String?
    let font: Font
    let height: CGFloat?
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let fillOpacity: Double
    let appliesGlassEffect: Bool
    let isActive: Bool
    let action: () -> Void

    init(
        _ title: String,
        accessibilityLabel: String? = nil,
        font: Font = .title3.weight(.heavy),
        height: CGFloat? = nil,
        horizontalPadding: CGFloat = 16,
        verticalPadding: CGFloat = 16,
        fillOpacity: Double = 1,
        appliesGlassEffect: Bool = false,
        isActive: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.accessibilityLabel = accessibilityLabel
        self.font = font
        self.height = height
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.fillOpacity = fillOpacity
        self.appliesGlassEffect = appliesGlassEffect
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        if appliesGlassEffect {
            button.glassEffect()
        } else {
            button
        }
    }

    private var button: some View {
        Button(action: action) {
            Text(title)
                .font(font)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: height)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(Color.accentColor.opacity(isActive ? fillOpacity : fillOpacity * 0.5), in: Capsule())
        .opacity(isActive ? 1 : 0.6)
        .disabled(!isActive)
        .accessibilityLabel(Text(accessibilityLabel ?? title))
    }
}

#Preview {
    PrimaryButton("Continue") {}
        .padding()
}
