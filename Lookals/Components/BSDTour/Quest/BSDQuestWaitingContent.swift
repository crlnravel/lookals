//
//  BSDQuestWaitingContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct BSDQuestWaitingContent: View {
    let quest: BSDQuest
    let message: String

    var body: some View {
        VStack(spacing: 32) {
            QuestExpandedHeader(label: quest.displayLabel, title: "Waiting", reward: quest.reward)

            ProgressView()
                .controlSize(.large)
                .tint(.accentColor)

            Text(message)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 40)
        .frame(minHeight: 420)
        .accessibilityElement(children: .combine)
    }
}
