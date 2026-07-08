//
//  QuizQuestContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import SwiftUI

struct QuizQuestContent: View {
    let questNumber: Int
    let title: String
    let question: String
    let options: [String]
    @Binding var selectedOption: String?
    let reward: Int
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            QuestExpandedHeader(questNumber: questNumber, title: title, reward: reward)

            Text(question)
                .font(.headline.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)

            VStack(spacing: 12) {
                ForEach(options, id: \.self) { option in
                    QuizOptionRow(
                        title: option,
                        isSelected: selectedOption == option
                    ) {
                        selectedOption = option
                    }
                }
            }

            PrimaryButton(
                "Submit",
                font: .headline.weight(.heavy),
                height: 24,
                verticalPadding: 16,
                isActive: selectedOption != nil,
                action: onSubmit
            )
            .padding(.top, 32)
        }
        .padding(.horizontal, 32)
        .padding(.top, 32)
        .padding(.bottom, 28)
    }
}

struct QuestExpandedHeader: View {
    let questNumber: Int
    let title: String
    let reward: Int

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                Text("QUEST \(questNumber)")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity)

            QuestRewardLabel(points: reward)
        }
    }
}

private struct QuizOptionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 12)

                Circle()
                    .strokeBorder(isSelected ? Color.accentColor : Color(.systemGray3), lineWidth: 1.5)
                    .background {
                        Circle()
                            .fill(isSelected ? Color.accentColor : .clear)
                            .padding(4)
                    }
                    .frame(width: 20, height: 20)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isSelected ? Color.accentColor : Color(.systemGray4), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    QuizQuestContent(
        questNumber: 1,
        title: "Quiz",
        question: "What's the name of Kelontong Poet-Tea owner?",
        options: ["Julian Yang", "Kevin Halim", "Carleano Ravel", "Gisella Jayanta"],
        selectedOption: .constant("Carleano Ravel"),
        reward: 30,
        onSubmit: {}
    )
    .background(Color(.systemBackground))
}
