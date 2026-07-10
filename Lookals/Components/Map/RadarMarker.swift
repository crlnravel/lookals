//
//  RadarMarker.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import SwiftUI

struct RadarMarker: View {
    let style: RadarMarkerStyle

    var body: some View {
        Group {
            switch style {
            case .avatar:
                avatarMarker
            case .participantAvatar(let imageName, let ringColor, _):
                participantAvatarMarker(imageName: imageName, ringColor: ringColor)
            case .smallDestination:
                destinationMarker
            case .place:
                placeMarker
            case .unknownCheckpoint:
                unknownCheckpointMarker
            case .landmark(let imageName, _):
                landmarkMarker(imageName: imageName)
            case .mapBadge(let label):
                mapBadge(label)
            }
        }
        .accessibilityLabel(style.accessibilityLabel)
    }

    private var avatarMarker: some View {
        Image("AvatarPlaceholder")
            .resizable()
            .scaledToFill()
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.accentColor, lineWidth: 5)
            )
            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
    }

    private func participantAvatarMarker(imageName: String?, ringColor: Color) -> some View {
        Image(imageName ?? "AvatarPlaceholder")
            .resizable()
            .scaledToFill()
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(ringColor, lineWidth: 5)
            )
            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
    }

    private var destinationMarker: some View {
        VStack(spacing: 0) {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(.white, lineWidth: 3))

            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 4, height: 22)

            Ellipse()
                .stroke(Color.accentColor, lineWidth: 4)
                .frame(width: 36, height: 12)
                .padding(.top, -2)
        }
        .shadow(color: .black.opacity(0.10), radius: 6, x: 0, y: 3)
    }

    private var placeMarker: some View {
        Image(systemName: "cup.and.saucer")
            .font(.system(size: 32, weight: .regular))
            .foregroundStyle(Color.brown)
            .frame(width: 68, height: 68)
            .background(Color.white.opacity(0.92), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.brown.opacity(0.82), lineWidth: 4)
            )
            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }

    private var unknownCheckpointMarker: some View {
        Image("BSDMap/QuestionMarkIcon")
            .resizable()
            .scaledToFit()
            .frame(width: 44, height: 44)
            .padding(8)
            .background(Color.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.brown.opacity(0.82), lineWidth: 4)
            )
            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }

    private func landmarkMarker(imageName: String) -> some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: 44, height: 44)
            .padding(8)
            .background(Color.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray), lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }

    private func mapBadge(_ label: String) -> some View {
        Text(label)
            .font(.subheadline.weight(.heavy))
            .foregroundStyle(Color(.darkGray))
            .frame(width: 42, height: 42)
            .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray), lineWidth: 3)
            )
            .shadow(color: .black.opacity(0.12), radius: 5, x: 0, y: 3)
    }
}

enum RadarMarkerStyle {
    case avatar
    case participantAvatar(imageName: String?, ringColor: Color, label: String)
    case smallDestination
    case place
    case unknownCheckpoint
    case landmark(imageName: String, label: String)
    case mapBadge(String)

    var accessibilityLabel: String {
        switch self {
        case .avatar:
            "Your location"
        case .participantAvatar(_, _, let label):
            label
        case .smallDestination:
            "Meeting point destination"
        case .place:
            "Kelontong Poet-Tea"
        case .unknownCheckpoint:
            "Unknown checkpoint"
        case .landmark(_, let label):
            label
        case .mapBadge(let label):
            "Map route \(label)"
        }
    }
}

#Preview("Radar Markers") {
    HStack(spacing: 32) {
        RadarMarker(style: .smallDestination)
        RadarMarker(style: .avatar)
        RadarMarker(style: .place)
        RadarMarker(style: .mapBadge("9A"))
    }
    .padding(32)
    .background(Color(.systemGray6))
}
