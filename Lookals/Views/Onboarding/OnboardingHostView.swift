//
//  OnboardingHostView.swift
//  Lookals
//
//  Created by Gisella Jayata on 12/07/26.
//


import SwiftUI

struct OnboardingHostView: View {
    @State private var path: [OnboardingStep] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 40) {
                Spacer()
                
                // Mascot Placeholder
                Image(systemName: "face.smiling")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .fontWeight(.ultraLight)
                
                VStack(spacing: 8) {
                    Text("Welcome Back!")
                        .font(.title.bold())
                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Single iCloud Login Button
                Button {
                    // Trigger CloudKit fetch here, then proceed:
                    path.append(.interests)
                } label: {
                    HStack {
                        Image(systemName: "icloud.fill")
                        Text("Continue with iCloud")
                    }
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.orange)
                    .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .navigationDestination(for: OnboardingStep.self) { step in
                switch step {
                case .interests:
                    InterestsView(path: $path)
                case .personality:
                    PersonalityView(path: $path)
                case .location:
                    LocationPermissionView(path: $path)
                case .success:
                    SuccessView(path: $path)
                }
            }
        }
    }
}

#Preview {
    OnboardingHostView()
}