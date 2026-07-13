//
//  SuccessView.swift
//  Lookals
//
//  Created by Gisella Jayata on 12/07/26.
//


import SwiftUI

struct SuccessView: View {
    @Binding var path: [OnboardingStep]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.orange)
            
            Text("Account Created!")
                .font(.largeTitle.bold())
            
            Text("You're all set and ready to explore.")
                .font(.body)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button {
                // Dismiss the entire onboarding flow and return to Home/Profile
                dismiss() 
            } label: {
                PrimaryButtonLabel(title: "Let's Go")
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SuccessView(path: .constant([]))
}