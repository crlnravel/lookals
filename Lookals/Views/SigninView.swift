//
//  SigninView.swift
//  Lookals
//
//  Created by Putri Aziza Mufva on 12/07/26.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {

    let onBack: () -> Void
    let onSignIn: () -> Void

    init(
        onBack: @escaping () -> Void = {},
        onSignIn: @escaping () -> Void = {}
    ) {
        self.onBack = onBack
        self.onSignIn = onSignIn
    }

    var body: some View {
        NavigationStack {
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
                                print("Authorization successful: \(authResults)")
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
                    Button(action: back) {
                        Label("", systemImage: "chevron.left")
                    }
                    .accessibilityLabel("Back to Log in View")
                    .padding()
                    .glassEffect()
                }
            }
        }
    }

    private func back() {
        onBack()
    }

    private func signIn() {
        onSignIn()
    }
}


#Preview {
    SignInView()
}
