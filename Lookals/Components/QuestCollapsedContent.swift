//
//  QuestCollapsedContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import SwiftUI

struct QuestCollapsedContent: View {
    let questNumber: Int
    let title: String
    let reward: Int

    init(
        questNumber: Int,
        title: String,
        reward: Int
    ) {
        self.questNumber = questNumber
        self.title = title
        self.reward = reward
    }

    var body: some View {
        HStack(spacing: 16) {
            Color.clear
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text("QUEST \(questNumber)")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer(minLength: 16)

            QuestRewardLabel(points: reward)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quest \(questNumber), \(title), \(reward) points")
    }
}

struct QuestRewardLabel: View {
    let points: Int

    var body: some View {
        Label("\(points)", systemImage: "star.fill")
            .font(.title3.weight(.heavy))
            .foregroundStyle(Color.accentColor)
            .labelStyle(.titleAndIcon)
            .accessibilityLabel("\(points) points")
    }
}

#Preview {
    QuestCollapsedContent(questNumber: 2, title: "Interact", reward: 30)
        .padding()
        .background(Color(.systemGray5))
}
