//
//  ShakePhoneCollapsedContent.swift
//  Lookals
//
//  Created by Codex on 09/07/26.
//

import SwiftUI

struct ShakePhoneCollapsedContent: View {
    var body: some View {
        HStack(spacing: 16) {
            Color.clear
                .frame(width: 48, height: 48)

            ShakePhoneAsset(size: .small)

            VStack(alignment: .leading, spacing: 8) {
                Text("Shake Your Phone!")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                ShakePhoneParticipantRow()
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Shake your phone to confirm your meetup")
    }
}

struct ShakePhoneParticipantRow: View {
    var body: some View {
        HStack(spacing: 4) {
            RadarMarker(style: .avatar)
                .frame(width: 28, height: 28)
                .scaleEffect(0.64)

            RadarMarker(style: .avatar)
                .frame(width: 28, height: 28)
                .scaleEffect(0.64)

            ShakePhoneParticipantRing(color: .blue)
            ShakePhoneParticipantRing(color: .green)
            ShakePhoneParticipantRing(color: .red)
        }
        .accessibilityHidden(true)
    }
}

struct ShakePhoneParticipantRing: View {
    let color: Color
    var size: CGFloat = 28

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 4)
            .frame(width: size, height: size)
    }
}

struct ShakePhoneAsset: View {
    enum Size {
        case small
        case large

        var width: CGFloat {
            switch self {
            case .small:
                61
            case .large:
                122
            }
        }

        var height: CGFloat {
            switch self {
            case .small:
                49
            case .large:
                97
            }
        }
    }

    let size: Size

    var body: some View {
        Image("ShakePhone")
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
        .accessibilityHidden(true)
    }
}

#Preview {
    ShakePhoneCollapsedContent()
        .frame(maxWidth: 392)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding()
        .background(Color(.systemGray5))
}
