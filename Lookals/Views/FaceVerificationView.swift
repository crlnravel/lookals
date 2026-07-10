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

    private var isLoading: Bool {
        switch viewModel.state {
        case .requestingCamera, .verifying:
            true
        case .idle, .complete, .cameraUnavailable:
            false
        }
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
        NavigationStack {
            GeometryReader { proxy in
                let previewWidth = min(proxy.size.width - 32, 340)
                let previewHeight = min(previewWidth / 0.84, proxy.size.height * 0.80)

                VStack(spacing: 20) {
                    cameraPreview
                        .frame(width: previewWidth, height: previewHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

                    instructionText

                    Spacer(minLength: 24)

                    VerificationProgressBar(progress: clampedProgress, percentage: progressPercentage)
                        .frame(height: 28)
                        .padding(.horizontal, 16)

                    doneButton
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .background(Color(.systemBackground))
            }
            .navigationTitle("Face Verification")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: backTapped) {
                        Label("", systemImage: "chevron.left")
                    }
                    .accessibilityLabel("Back")
                    .padding()
                    .glassEffect()
                }
            }
        }
        .task {
            guard startsAutomatically else { return }
            viewModel.start()
        }
        .onDisappear {
            viewModel.cancel()
        }
    }

    @ViewBuilder
    private var cameraPreview: some View {
        if let capturedFaceImage = viewModel.capturedFaceImage {
            Image(uiImage: capturedFaceImage)
                .resizable()
                .scaledToFill()
                .accessibilityLabel("Captured face verification image")
        } else if viewModel.shouldShowCameraPreview && startsAutomatically {
            FaceCameraPreview(session: viewModel.captureSession)
                .accessibilityLabel("Live face verification camera preview")
        } else {
            CameraPreviewPlaceholder(state: viewModel.state)
        }
    }

    private var instructionText: some View {
        VStack(spacing: 12) {
            Text(viewModel.instruction)
                .multilineTextAlignment(.center)
            
            if isLoading {
                ProgressView()
                    .controlSize(.regular)
                    .tint(.accentColor)
                    .transition(.scale.combined(with: .opacity))
            }

        }
        .animation(.smooth(duration: 0.25), value: isLoading)
        .animation(.default, value: viewModel.instruction)
    }

    private var doneButton: some View {
        PrimaryButton(
            "Done",
            font: .default.weight(.heavy),
            isActive: viewModel.isComplete,
            action: doneTapped
        )
        .padding(.horizontal, 16)
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
                    .fill(Color.accent.gradient.opacity(0.85))
                    .frame(width: max(proxy.size.height, proxy.size.width * progress))
                    .animation(.smooth(duration: 0.35), value: progress)

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
