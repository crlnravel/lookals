//
//  FaceVerificationView.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import SwiftUI

struct FaceVerificationView: View {
    @State private var viewModel: FaceVerificationViewModel

    let startsAutomatically: Bool
    let onBack: () -> Void
    let onDone: () -> Void

    private var clampedProgress: Double {
        min(max(viewModel.progress, 0), 1)
    }

    private var progressPercentage: Int {
        Int((clampedProgress * 100).rounded())
    }

    init(
        viewModel: FaceVerificationViewModel? = nil,
        startsAutomatically: Bool = true,
        onBack: @escaping () -> Void = {},
        onDone: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: viewModel ?? FaceVerificationViewModel())
        self.startsAutomatically = startsAutomatically
        self.onBack = onBack
        self.onDone = onDone
    }

    var body: some View {
        GeometryReader { proxy in
            let previewWidth = min(proxy.size.width - 64, 340)
            let previewHeight = min(previewWidth / 0.84, proxy.size.height * 0.46)

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 32)
                    .padding(.top, 8)

                cameraPreview
                    .frame(width: previewWidth, height: previewHeight)
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
        .task {
            guard startsAutomatically else { return }
            viewModel.start()
        }
        .onDisappear {
            viewModel.cancel()
        }
    }

    private var header: some View {
        ZStack {
            Text("Face Verification")
                .font(.title3.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            HStack {
                Button(action: backTapped) {
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

    @ViewBuilder
    private var cameraPreview: some View {
        if viewModel.shouldShowCameraPreview && startsAutomatically {
            FaceCameraPreview(session: viewModel.captureSession)
                .accessibilityLabel("Live face verification camera preview")
        } else {
            CameraPreviewPlaceholder(state: viewModel.state)
        }
    }

    private var instructionText: some View {
        Text(viewModel.instruction)
            .font(.title3)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .foregroundStyle(.primary)
            .padding(.horizontal, 32)
            .animation(.default, value: viewModel.instruction)
    }

    private var doneButton: some View {
        Button(action: doneTapped) {
            Text("Done")
                .font(.title3.weight(.heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 64)
        }
        .background(viewModel.isComplete ? Color.accentColor : Color(.systemGray4), in: Capsule())
        .disabled(!viewModel.isComplete)
        .accessibilityLabel("Done")
    }

    private func backTapped() {
        viewModel.cancel()
        onBack()
    }

    private func doneTapped() {
        guard viewModel.isComplete else { return }
        onDone()
    }
}

private struct CameraPreviewPlaceholder: View {
    let state: FaceVerificationViewModel.State

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground)

            VStack(spacing: 12) {
                Image(systemName: symbolName)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }

    private var symbolName: String {
        switch state {
        case .cameraUnavailable:
            "camera.fill.badge.ellipsis"
        case .complete:
            "checkmark.circle.fill"
        case .idle, .requestingCamera, .verifying:
            "camera.fill"
        }
    }

    private var title: String {
        switch state {
        case .cameraUnavailable:
            "Camera unavailable"
        case .complete:
            "Verified"
        case .idle, .requestingCamera, .verifying:
            "Camera preview"
        }
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
    FaceVerificationView(
        viewModel: .preview(state: .verifying(.scanningFace), progress: 0.85),
        startsAutomatically: false
    )
}

#Preview("Complete") {
    FaceVerificationView(
        viewModel: .preview(state: .complete, progress: 1),
        startsAutomatically: false
    )
}
