//
//  InterestsView.swift
//  Lookals
//
//  Created by Gisella Jayata on 12/07/26.
//

import SwiftUI

struct PersonalityView: View {
    @Binding var path: [OnboardingStep]
    @EnvironmentObject var onboardingData: OnboardingData
    @State private var selectedPersonality: Personality = .unselected
    @State private var isSaving: Bool = false // Indikator loading

    private enum Personality: String, CaseIterable {
        case unselected = "Select Personality"
        case introvert = "Introvert"
        case extrovert = "Extrovert"
        case ambivert = "Ambivert"
    }
    
    var body: some View {
        OnboardingTemplate(
            title: "What's your personality?",
            subtitle: "This helps us find the best Lookals connections for you.",
            bgImageName: "profileSetupBg",
            onBack: { path.removeLast() },
            circleYOffset: 250,
        ) {
            CustomDropdown(
                title: "Personality",
                selection: $selectedPersonality,
                options: Personality.allCases.filter { $0 != .unselected }
            )
            .padding(.bottom, 24)
            
            
            Button {
                print("Tombol Next ditekan! Memulai upload...")
                isSaving = true
                onboardingData.personality = selectedPersonality.rawValue
                
                #if LOOKALS_CLOUDKIT
                CloudKitManager.shared.saveUserProfile(data: onboardingData) { success in
                    isSaving = false
                    if success {
                        print("Upload Berhasil! Pindah halaman...")
                        path.append(.location)
                    } else {
                        print("YAH GAGAL UPLOAD KE CLOUDKIT! 😭")
                    }
                }
                #else
                isSaving = false
                path.append(.location)
                #endif
            } label: {
                if isSaving {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.orange).clipShape(Capsule())
                } else {
                    PrimaryButtonLabel(title: "Next")
                }
            }
            .disabled(selectedPersonality == .unselected || isSaving)
        }
    }
}

#Preview {
    NavigationStack {
        PersonalityView(path: .constant([]))
            .environmentObject(OnboardingData())
    }
}
