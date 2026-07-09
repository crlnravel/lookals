//
//  BSDQuestContentPreviewContainer.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct BSDQuestContentPreviewContainer<ExpandedContent: View>: View {
    let quest: BSDQuest
    let step: BSDQuestStep
    let expandedContent: ExpandedContent

    @State private var isExpanded = true

    init(
        quest: BSDQuest,
        step: BSDQuestStep,
        @ViewBuilder expandedContent: () -> ExpandedContent
    ) {
        self.quest = quest
        self.step = step
        self.expandedContent = expandedContent()
    }

    var body: some View {
        ZStack {
            Color(.systemGray5)
                .ignoresSafeArea()

            ExpandableWidget(
                isExpanded: $isExpanded,
                collapsedMaxWidth: 392,
                expandedMaxWidth: 360,
                horizontalPadding: 20,
                edgePadding: 16
            ) {
                BSDTourQuestCollapsedContent(quest: quest, step: step)
            } expandedContent: {
                expandedContent
            }
        }
    }
}
