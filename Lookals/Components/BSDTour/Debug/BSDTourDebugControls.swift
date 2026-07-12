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

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                isExpanded.toggle()
            } label: {
                Label("Debug", systemImage: "wrench.and.screwdriver")
                    .font(.caption.weight(.bold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.phase.rawValue)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 8)], spacing: 8) {
                        debugButton("Arrive", action: viewModel.simulateArrival)
                        debugButton("Leave", action: viewModel.simulateLeavingArrivalRadius)
                        debugButton("Shake") { shakeDetector.simulateShake() }
                        debugButton("Join Mock", action: viewModel.joinNextMockParticipant)
                        debugButton("Join All", action: viewModel.joinAllParticipants)
                        debugButton("Cutoff", action: viewModel.triggerCutoff)
                        debugButton("Complete All", action: viewModel.completeCurrentQuestForAllParticipants)
                        debugButton("Finish", action: viewModel.finishTour)
                        debugButton("Reset", role: .destructive, action: viewModel.reset)
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(.horizontal, 20)
    }

    private func debugButton(
        _ title: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, role: role, action: action)
            .font(.caption.weight(.semibold))
            .buttonStyle(.bordered)
            .controlSize(.small)
    }
}
#endif
