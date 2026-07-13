//
//  MiniQuestView.swift
//  Lookals
//
//  Created by Kevin Halim on 12/07/26.
//

import SwiftUI
import UIKit

struct MiniQuestView: View {
    let onBack: () -> Void
    let onStartExploring: () -> Void

    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var isShowingCamera = false
    @State private var isCompleted = false

    private let reward = 50

    init(
        onBack: @escaping () -> Void = {},
        onStartExploring: @escaping () -> Void = {}
    ) {
        self.onBack = onBack
        self.onStartExploring = onStartExploring
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                

                if isCompleted {
                    MiniQuestConfirmationView(
                        reward: reward,
                        user: profileViewModel.user,
                        onStartExploring: onStartExploring
                    )
                } else {
                    MiniQuestPromptView(
                        onTakePicture: showCamera
                    )
                }
            }
            .toolbar(isCompleted ? .hidden : .visible, for: .navigationBar)
            .toolbar {
                if !isCompleted {
                    ToolbarIconButton(
                        placement: .topBarLeading,
                        systemImage: "chevron.left",
                        accessibilityLabel: "Go back",
                        action: onBack
                    )

                    ToolbarItem(placement: .topBarTrailing) {
                        MiniQuestPointsToolbar(points: reward)
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            CameraCaptureSheet { _ in
                isCompleted = true
                isShowingCamera = false
            } onCancel: {
                isShowingCamera = false
            }
        }
    }

    private func showCamera() {
        isShowingCamera = true
    }
}

private struct MiniQuestPromptView: View {
    let onTakePicture: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            MiniQuestHeader()

            Spacer(minLength: 20)

            Image("MiniQuestBg")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 244)
                .clipped()
                .accessibilityLabel("Local market booth")

            Spacer()

            PrimaryButton(
                "Take a Picture",
                accessibilityLabel: "Take a picture for the mini quest",
                font: .headline.weight(.heavy),
                height: 56,
                verticalPadding: 0,
                action: onTakePicture
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

private struct MiniQuestHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("MINI QUEST")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.primary)

                Text("Stroll Around!")
                    .font(.system(size: 36, weight: .black))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.78)

                Text("The security guards and cleaners\nare the real locals here.\nDon't be a stranger.\n\nIntroduce yourself to them and\nsnap a quick pic!")
                    .font(.title3.weight(.medium))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

private struct MiniQuestPointsToolbar: View {
    let points: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.fill")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .padding(6)
                .background(Circle().fill(Color.accentColor))
                .accessibilityHidden(true)

            Text("\(points)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(points) points")
    }
}

private struct MiniQuestConfirmationView: View {
    let reward: Int
    let user: User
    let onStartExploring: () -> Void

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ConfettiView(isActive: .constant(true))

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Not invisible anymore!")
                        .font(.system(size: 28, weight: .black))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.78)

                    Text("A city is just empty buildings\nuntil you know the people\nkeeping it alive")
                        .font(.system(size: 17, weight: .medium))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .foregroundStyle(.primary)
                }

                MiniQuestProfileBadge(user: user)

                MiniQuestPointsReceivedView(points: reward)

                Spacer()

                PrimaryButton(
                    "Start Exploring",
                    accessibilityLabel: "Start exploring",
                    font: .headline.weight(.heavy),
                    height: 56,
                    verticalPadding: 0,
                    action: onStartExploring
                )
                .padding(.bottom, 32)
            }
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }
}

private struct MiniQuestProfileBadge: View {
    let user: User

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                profileImage
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())

                Image(user.level.badgeImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 148, height: 148)
                    .accessibilityHidden(true)
            }

            Text("The \(user.level.title)")
                .font(.headline.weight(.black))
                .italic()
                .foregroundStyle(.primary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The \(user.level.title) badge")
    }

    @ViewBuilder
    private var profileImage: some View {
        if let imageData = user.customImageData, let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            Image(user.profileImageName)
                .resizable()
                .scaledToFill()
        }
    }
}

private struct MiniQuestPointsReceivedView: View {
    let points: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Color.accentColor, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Text("Lookals points earned")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.accentColor.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("+\(points)")
                    .font(.title2.weight(.black))
                    .foregroundStyle(Color.accentColor)
            }

            Spacer()

            Text("\(points) total")
                .font(.caption2.weight(.medium))
                .foregroundStyle(Color.accentColor.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .frame(height: 70)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(points) Lookals points earned, \(points) total")
    }
}

#Preview("Mini Quest") {
    MiniQuestView()
}
