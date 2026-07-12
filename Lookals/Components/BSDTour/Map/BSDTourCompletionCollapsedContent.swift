//
//  BSDTourCompletionCollapsedContent.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct BSDTourCompletionCollapsedContent: View {
    let points: Int

    var body: some View {
        HStack(spacing: 16) {
            Color.clear
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text("Tour Complete")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.primary)

                Text("\(points) points earned")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            QuestRewardLabel(points: points)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}
