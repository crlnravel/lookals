//
//  BSDTourCompletionExpandedContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct BSDTourCompletionExpandedContent: View {
    let points: Int
    let participants: [BSDTourParticipantDisplay]
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                Text("Tour Complete")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                Text("You finished the BSD route.")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 80)

            ShakePhoneParticipantRow(participants: participants)
                .scaleEffect(1.35)
                .frame(height: 56)

            QuestRewardLabel(points: points)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            PrimaryButton(
                "Finish Tour",
                font: .headline.weight(.heavy),
                action: onFinish
            )
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
        .frame(minHeight: 520)
    }
}
