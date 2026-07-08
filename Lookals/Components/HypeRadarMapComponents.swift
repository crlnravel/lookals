//
//  HypeRadarMapComponents.swift
//  Lookals
//
//  Created by Codex on 09/07/26.
//

import SwiftUI

struct MapTopBar: View {
    let title: String
    let onBack: () -> Void
    let onLocate: () -> Void

    var body: some View {
        HStack {
            circularButton(
                systemImage: "chevron.left",
                accessibilityLabel: "Go back",
                action: onBack
            )

            Spacer()

            Text(title)
                .font(.title3.weight(.heavy))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer()

            circularButton(
                systemImage: "location.north.fill",
                accessibilityLabel: "Show current location",
                foregroundStyle: .white,
                backgroundStyle: AnyShapeStyle(Color.accentColor),
                action: onLocate
            )
        }
        .frame(height: 48)
        .padding(.top, 48)
    }

    private func circularButton(
        systemImage: String,
        accessibilityLabel: String,
        foregroundStyle: Color = .primary,
        backgroundStyle: AnyShapeStyle = AnyShapeStyle(.ultraThinMaterial),
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(foregroundStyle)
                .frame(width: 48, height: 48)
                .background(backgroundStyle, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect()
        .accessibilityLabel(accessibilityLabel)
    }
}

struct CloudOverlay: View {
    private let clouds = [
        CloudPlacement(x: 0.18, y: 0.12, width: 260, opacity: 1, rotation: -8),
        CloudPlacement(x: 0.68, y: 0.13, width: 320, opacity: 1, rotation: 7),
        CloudPlacement(x: 0.86, y: 0.34, width: 280, opacity: 1, rotation: -12),
        CloudPlacement(x: 0.22, y: 0.80, width: 300, opacity: 1, rotation: 10),
        CloudPlacement(x: 0.70, y: 0.86, width: 340, opacity: 1, rotation: -5),
        CloudPlacement(x: 0.47, y: 0.43, width: 360, opacity: 1, rotation: 4)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white.opacity(0.16)

                ForEach(clouds) { cloud in
                    Image("Cloud")
                        .resizable()
                        .scaledToFit()
                        .frame(width: cloud.width)
                        .opacity(cloud.opacity)
                        .rotationEffect(.degrees(cloud.rotation))
                        .position(
                            x: proxy.size.width * cloud.x,
                            y: proxy.size.height * cloud.y
                        )
                        .blendMode(.screen)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct RadarMarker: View {
    let style: RadarMarkerStyle

    var body: some View {
        Group {
            switch style {
            case .avatar:
                avatarMarker
            case .smallDestination:
                destinationMarker
            case .place:
                placeMarker
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
    case smallDestination
    case place
    case mapBadge(String)

    var accessibilityLabel: String {
        switch self {
        case .avatar:
            "Your location"
        case .smallDestination:
            "Meeting point destination"
        case .place:
            "Kelontong Poet-Tea"
        case .mapBadge(let label):
            "Map route \(label)"
        }
    }
}

struct BottomStatusCard: View {
    let state: HypeRadarMapState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch state {
            case .goingToMeetingPoint:
                goingContent
            case .arrived:
                arrivedContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(maxWidth: 392)
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 20, x: 0, y: 10)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    private var goingContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Go to Meeting Point")
                .font(.title3.weight(.heavy))
                .foregroundStyle(.primary)

            HStack(alignment: .center, spacing: 16) {
                RadarMarker(style: .smallDestination)
                    .frame(width: 28, height: 32)
                    .scaleEffect(0.60)
                    .foregroundStyle(Color.accentColor)

                Text("Kelontong Poet-Tea Jl. BSD\nRaya Barat.")
                    .font(.body.weight(.regular))
                    .foregroundStyle(.primary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var arrivedContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Kelontong Poet-Tea")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(.primary)

                Text("You’ve arrived!")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                Capsule()
                    .fill(Color.accentColor)
                    .frame(height: 6)

                RadarMarker(style: .avatar)
                    .frame(width: 40, height: 40)
                    .scaleEffect(0.78)
                    .padding(.leading, -4)

                RadarMarker(style: .smallDestination)
                    .frame(width: 32, height: 32)
                    .scaleEffect(0.56)
                    .padding(.leading, 8)
            }
        }
    }
}

private struct CloudPlacement: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let opacity: Double
    let rotation: Double
}
