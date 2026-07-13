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
    @State private var selectedPersonality: String = "Select Personality"
    @State private var isSaving: Bool = false // Indikator loading
    
    let personalities = ["Select Personality", "Introvert", "Extrovert", "Ambivert"]
    
    var body: some View {
        OnboardingTemplate(
            title: "What's your personality?",
            subtitle: "This helps us find the best Lookals connections for you.",
            bgImageName: "profileSetupBg",
            onBack: { path.removeLast() },
            circleYOffset: 250,
        ) {
            Menu {
                ForEach(personalities.dropFirst(), id: \.self) { trait in
                    Button(trait) {
                        selectedPersonality = trait
                    }
                }
            } label: {
                HStack {
                    Text(selectedPersonality)
                        .foregroundColor(selectedPersonality == "Select Personality" ? .gray : .black)
                    Spacer()
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .padding()
                .contentShape(Rectangle())
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

            }
            .padding(.bottom, 100)
            
            
            Button {
                print("Tombol Next ditekan! Memulai upload...")
                isSaving = true
                onboardingData.personality = selectedPersonality
                
                CloudKitManager.shared.saveUserProfile(data: onboardingData) { success in
                    isSaving = false
                    if success {
                        print("Upload Berhasil! Pindah halaman...")
                        path.append(.location)
                    } else {
                        print("YAH GAGAL UPLOAD KE CLOUDKIT! 😭")
                    }
                }
            } label: {
                if isSaving {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.orange).clipShape(Capsule())
                } else {
                    PrimaryButtonLabel(title: "Next")
                }
            }
            .disabled(selectedPersonality == "Select Personality" || isSaving)
            .disabled(selectedPersonality == "Select Personality" || isSaving)
        }
    }
}

#Preview {
    NavigationStack {
        PersonalityView(path: .constant([]))
            .environmentObject(OnboardingData())
    }
}
