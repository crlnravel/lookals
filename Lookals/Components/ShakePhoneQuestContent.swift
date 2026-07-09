//
//  ShakePhoneQuestContent.swift
//  Lookals
//
//  Created by Codex on 09/07/26.
//

import SwiftUI

struct ShakePhoneQuestContent: View {
    var body: some View {
        VStack(spacing: 24) {
            ShakePhoneAsset(size: .large)

            VStack(spacing: 16) {
                Text("Shake Your\nPhone")
                    .font(.system(size: 36, weight: .heavy))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)

                Text("Shake your iPhone close to their iPhone to confirm your meetup.")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ShakePhoneExpandedParticipantCluster()
                .padding(.top, 8)
        }
        .padding(.horizontal, 40)
        .padding(.top, 80)
        .padding(.bottom, 40)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Shake your phone. Shake your iPhone close to their iPhone to confirm your meetup.")
    }
}

private struct ShakePhoneExpandedParticipantCluster: View {
    var body: some View {
        ZStack {
            ShakePhoneParticipantRing(color: .red, size: 58)
                .offset(x: -44, y: -28)

            ShakePhoneParticipantRing(color: .blue, size: 76)
                .offset(x: 40, y: -44)

            ShakePhoneParticipantRing(color: .green, size: 64)
                .offset(x: 76, y: 28)

            RadarMarker(style: .avatar)
                .frame(width: 48, height: 48)
                .offset(x: -64, y: 32)

            RadarMarker(style: .avatar)
                .frame(width: 42, height: 42)
                .scaleEffect(0.86)
                .offset(x: -12, y: 24)
        }
        .frame(width: 196, height: 132)
        .accessibilityHidden(true)
    }
}

#Preview {
    ShakePhoneQuestContent()
        .frame(maxWidth: 360)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 32, style: .continuous))
        .padding()
        .background(Color(.systemGray5))
}
