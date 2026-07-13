//
//  BSDTourUnavailableCard.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct BSDTourUnavailableCard: View {
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.xmark")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: 4) {
                Text("Tour Unavailable")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.primary)

                Text("The waiting room closed before you joined.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            PrimaryButton(
                "Go Back",
                font: .headline.weight(.heavy),
                action: onBack
            )
        }
        .frame(maxWidth: 392)
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 20, x: 0, y: 10)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}
