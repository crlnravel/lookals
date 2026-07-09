//
//  HypeRadarFloatingControls.swift
//  Lookals
//
//  Created by Codex on 09/07/26.
//

import SwiftUI

struct HypeRadarPointsBadge: View {
    let points: Int

    var body: some View {
        Label("\(points)", systemImage: "star.fill")
            .font(.title3.weight(.heavy))
            .foregroundStyle(Color.accentColor)
            .labelStyle(.titleAndIcon)
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Color(.systemBackground), in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
            .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
            .accessibilityLabel("\(points) points")
    }
}

struct HypeRadarCameraButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "camera")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(Color.accentColor, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect()
        .accessibilityLabel("Open camera")
    }
}

#Preview("Floating Controls") {
    HStack(spacing: 24) {
        HypeRadarPointsBadge(points: 0)
        HypeRadarCameraButton(action: {})
    }
    .padding()
    .background(Color(.systemGray5))
}
