//
//  LoginView.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedImageIndex = 0

    let onGetStarted: () -> Void
    let onSignIn: () -> Void

    private let backgroundImages = ["Login Image 1", "Login Image 2"]
    private let imageChangeDelay: UInt64 = 3_500_000_000

    init(
        onGetStarted: @escaping () -> Void = {},
        onSignIn: @escaping () -> Void = {}
    ) {
        self.onGetStarted = onGetStarted
        self.onSignIn = onSignIn
    }

    var body: some View {
        ZStack {
            LoginBackgroundView(
                imageNames: backgroundImages,
                selectedImageIndex: selectedImageIndex,
                reduceMotion: reduceMotion
            )

            VStack(spacing: 16) {
                Spacer()

                Button(action: getStarted) {
                    Text("Get Started")
                        .font(.default.weight(.heavy))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color.accentColor.opacity(0.9))
                .clipShape(Capsule())
                .glassEffect()

                HStack(spacing: 8) {
                    Text("Already have an account?")
                        .font(.default)
                        .foregroundStyle(.white)

                    Button(action: signIn) {
                        Text("Sign In")
                            .font(.default.bold())
                            .foregroundStyle(.white)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    .accessibilityInputLabels(["Sign In"])
                }
                .padding(.bottom, 56)
            }
            .frame(width: .infinity)
            .padding(16)
        }
        .ignoresSafeArea()
        .task {
            await rotateBackgroundImages()
        }
    }

    private func rotateBackgroundImages() async {
        guard backgroundImages.count > 1 else { return }

        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: imageChangeDelay)

            if Task.isCancelled { return }

            if reduceMotion {
                selectedImageIndex = (selectedImageIndex + 1) % backgroundImages.count
            } else {
                withAnimation(.easeInOut(duration: 0.8)) {
                    selectedImageIndex = (selectedImageIndex + 1) % backgroundImages.count
                }
            }
        }
    }

    private func getStarted() {
        onGetStarted()
    }

    private func signIn() {
        onSignIn()
    }
}

#Preview {
    LoginView()
}
