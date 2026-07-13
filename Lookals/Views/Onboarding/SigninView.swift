//
//  SignInView.swift
//  Lookals
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @State private var path: [OnboardingStep] = []
    @StateObject private var onboardingData = OnboardingData()
    @AppStorage("isSignedIn") private var isSignedIn = false
    @Environment(\.dismiss) var dismiss


    let onBack: () -> Void

    init(onBack: @escaping () -> Void = {}) {
        self.onBack = onBack
    }

    var body: some View {
        
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 60)

                    Image("signin-1")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 340, maxHeight: 270)

                    VStack(spacing: 10) {
                        Text("One step away from becoming a Lookals!")
                            .font(.title.bold())
                            .foregroundStyle(.primary)

                        Text("This city's about to feel different.\nSign in first.")
                            .font(.body)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 30)

                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authResults):
                                if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                        if let givenName = appleIDCredential.fullName?.givenName {
                                            onboardingData.fullName = givenName
                                        }
                                        if let email = appleIDCredential.email {
                                            onboardingData.email = email
                                        }
                                    }
                                path.append(.interests)
                            case .failure(let error):
                                print("Authorization failed: \(error.localizedDescription)")
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 54)
                    .cornerRadius(14)
                    .padding(.top, 30)

                    Spacer(minLength: 56)
                }
                .padding(.horizontal, 40)
            }
            .background(
                ZStack(alignment: .top) {
                    Color.white
                        .ignoresSafeArea()
                    
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 800, height: 800)
                        .offset(y: 70)
                }
            )
            .navigationTitle("Sign In")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Label("", systemImage: "chevron.left")
                    }
                    .accessibilityLabel("Back to Log in View")
                    .padding()
                    .glassEffect()
                }
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
        .environmentObject(onboardingData)
        .onChange(of: isSignedIn) { newValue in
            if newValue == true {
                dismiss()
            }
        }
    }

    private func back() {
        onBack()
    }
}

#Preview {
    SignInView()
}
