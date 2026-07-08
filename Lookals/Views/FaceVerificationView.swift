//
//  FaceVerificationView.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct FaceVerificationView: View {
    let image: Image
    let progress: Double
    let onBack: () -> Void
    let onDone: () -> Void

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var progressPercentage: Int {
        Int((clampedProgress * 100).rounded())
    }

    private var isComplete: Bool {
        clampedProgress >= 1
    }

    init(
        image: Image = Image("Login Image 1"),
        progress: Double = 0.85,
        onBack: @escaping () -> Void = {},
        onDone: @escaping () -> Void = {}
    ) {
        self.image = image
        self.progress = progress
        self.onBack = onBack
        self.onDone = onDone
    }

    var body: some View {
        GeometryReader { proxy in
            let imageWidth = min(proxy.size.width - 64, 340)
            let imageHeight = min(imageWidth / 0.84, proxy.size.height * 0.46)

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 32)
                    .padding(.top, 8)

                faceImage
                    .frame(width: imageWidth, height: imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .padding(.top, 8)

                instructionText
                    .padding(.top, 20)

                Spacer(minLength: 32)

                VerificationProgressBar(progress: clampedProgress, percentage: progressPercentage)
                    .frame(height: 28)
                    .padding(.horizontal, 32)

                Spacer()
                    .frame(height: 72)

                doneButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(Color(.systemBackground))
        }
    }

    private var header: some View {
        ZStack {
            Text("Face Verification")
                .font(.title3.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 56, height: 56)
                }
                .buttonStyle(.plain)
                .glassEffect()
                .accessibilityLabel("Back")

                Spacer()
            }
        }
        .frame(height: 64)
    }

    private var faceImage: some View {
        image
            .resizable()
            .scaledToFill()
            .accessibilityLabel("Face verification photo")
    }

    private var instructionText: some View {
        Text("Please hold your face and wait.\nWe are verifying your face.")
            .font(.title3)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .foregroundStyle(.primary)
            .padding(.horizontal, 32)
    }

    private var doneButton: some View {
        Button(action: onDone) {
            Text("Done")
                .font(.title3.weight(.heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
        }
        .background(isComplete ? Color.accentColor : Color(.systemGray4), in: Capsule())
        .disabled(!isComplete)
        .accessibilityLabel("Done")
    }
}

private struct VerificationProgressBar: View {
    let progress: Double
    let percentage: Int

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray4))

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(proxy.size.height, proxy.size.width * progress))

                Text("\(percentage)%")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .minimumScaleFactor(0.8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Verification progress")
        .accessibilityValue("\(percentage) percent")
    }
}

#Preview("In Progress") {
    FaceVerificationView(progress: 0.85)
}

#Preview("Complete") {
    FaceVerificationView(progress: 1)
}
