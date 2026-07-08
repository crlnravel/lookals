//
//  InteractQuestContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import SwiftUI

struct InteractQuestContent<Media: View>: View {
    let questNumber: Int
    let title: String
    let heading: String
    let description: String
    let buttonTitle: String
    let buttonSystemImage: String
    let reward: Int
    let media: Media
    let onConfirm: () -> Void

    init(
        questNumber: Int,
        title: String,
        heading: String,
        description: String,
        buttonTitle: String,
        buttonSystemImage: String = "camera",
        reward: Int,
        @ViewBuilder media: () -> Media,
        onConfirm: @escaping () -> Void
    ) {
        self.questNumber = questNumber
        self.title = title
        self.heading = heading
        self.description = description
        self.buttonTitle = buttonTitle
        self.buttonSystemImage = buttonSystemImage
        self.reward = reward
        self.media = media()
        self.onConfirm = onConfirm
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                QuestExpandedHeader(questNumber: questNumber, title: title, reward: reward)
            }
            .padding(.horizontal, 32)
            .padding(.top, 32)
            .padding(.bottom, 20)

            media
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
                .overlay(alignment: .bottom) {
                    LinearGradient(
                        colors: [.clear, Color(.systemBackground)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 80)
                }

            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(heading)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)

                    Text(description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button(action: onConfirm) {
                    Label(buttonTitle, systemImage: buttonSystemImage)
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.accentColor, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(buttonTitle)
            }
            .padding(.horizontal, 32)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
    }
}

#Preview {
    InteractQuestContent(
        questNumber: 2,
        title: "Interact!",
        heading: "Talk to the Barista",
        description: "Ask them about the coffee shop's history - when did it open, and what's the story behind the name?",
        buttonTitle: "Scan to Confirm",
        reward: 30
    ) {
        Image(systemName: "person.crop.rectangle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(Color(.systemGray3))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGray6))
    } onConfirm: {}
    .background(Color(.systemBackground))
}
