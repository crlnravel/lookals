//
//  BSDTourDebugControls.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

#if DEBUG
import SwiftUI

struct BSDTourDebugControls: View {
    @Bindable var viewModel: BSDTourViewModel
    let shakeDetector: BSDTourShakeDetector
    @Binding var isPresented: Bool
    let onFactRequested: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.phase.rawValue)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                debugButton("Arrive", action: viewModel.simulateArrival)
                debugButton("RM Medan Ria → 5s", action: viewModel.previewArrivalFromMedanRia)
                debugButton("Leave", action: viewModel.simulateLeavingArrivalRadius)
                debugButton("Shake") { shakeDetector.simulateShake() }
                debugButton("Join Mock", action: viewModel.joinNextMockParticipant)
                debugButton("Join All", action: viewModel.joinAllParticipants)
                debugButton("Fact") {
                    viewModel.showLookalsFactDebug()
                    onFactRequested()
                }
                debugButton("Cutoff", action: viewModel.triggerCutoff)
                debugButton("Complete All", action: viewModel.completeCurrentQuestForAllParticipants)
                debugButton("Finish", action: viewModel.finishTour)
                debugButton("Reset", role: .destructive, action: viewModel.reset)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func debugButton(
        _ title: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, role: role) {
            action()
            isPresented = false
        }
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)
            .controlSize(.small)
    }
}

#endif
