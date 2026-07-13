//
//  InterestsView.swift
//  Lookals
//
//  Created by Gisella Jayata on 12/07/26.
//

import SwiftUI

struct NameInputView: View {
    @Binding var path: [OnboardingStep]
    @EnvironmentObject var onboardingData: OnboardingData
    @State private var nickname: String = ""
    
    var body: some View {
        OnboardingTemplate(
            title: "What should we call you?",
            subtitle: "This will be your nickname inside the app.",
            bgImageName: "profileSetupBg", 
            onBack: { path.removeLast() },
            circleYOffset: 250
        ) {
            VStack(spacing: 20) {
                TextField("Enter your nickname", text: $nickname)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.bottom, 80)
                
                Button {
                    onboardingData.fullName = nickname
                } label: {
                    PrimaryButtonLabel(title: "Next")
                }
                .disabled(nickname.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack {
        NameInputView(path: .constant([]))
            .environmentObject(OnboardingData())
    }
}
