//
//  HypeRadarQuizWidget.swift
//  Lookals
//
//  Created by Codex on 09/07/26.
//

import SwiftUI

struct HypeRadarQuizWidget: View {
    @Binding var isExpanded: Bool
    @Binding var selectedOption: String?
    let onSubmit: () -> Void

    var body: some View {
        ExpandableWidget(
            isExpanded: $isExpanded,
            collapsedMaxWidth: 392,
            expandedMaxWidth: 360,
            horizontalPadding: 20,
            edgePadding: 16
        ) {
            QuestCollapsedContent(
                questNumber: 1,
                title: "Quiz",
                reward: 30
            )
        } expandedContent: {
            QuizQuestContent(
                questNumber: 1,
                title: "Quiz",
                question: "What’s the name of Kelontong Poet-Tea owner?",
                options: ["Julian Yang", "Kevin Halim", "Carleano Ravel", "Gisella Jayanta"],
                selectedOption: $selectedOption,
                reward: 30,
                onSubmit: onSubmit
            )
        }
    }
}

#Preview("Hype Radar Quiz Widget") {
    struct PreviewHost: View {
        @State private var isExpanded = true
        @State private var selectedOption: String?

        var body: some View {
            HypeRadarQuizWidget(
                isExpanded: $isExpanded,
                selectedOption: $selectedOption,
                onSubmit: {}
            )
        }
    }

    return PreviewHost()
}
