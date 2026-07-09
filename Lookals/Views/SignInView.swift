//
//  SignInView.swift
//  Lookals
//
//  Created by Putri Aziza Mufva on 09/07/26.
//

import SwiftUI

struct SignInView: View {
    @State private var phoneNumber = ""
    @State private var password = ""

    let onBack: () -> Void
    let onSignIn: () -> Void
    let onForgotPassword: () -> Void
    let onSignUp: () -> Void

    init(
        onBack: @escaping () -> Void = {},
        onSignIn: @escaping () -> Void = {},
        onForgotPassword: @escaping () -> Void = {},
        onSignUp: @escaping () -> Void = {}
    ) {
        self.onBack = onBack
        self.onSignIn = onSignIn
        self.onForgotPassword = onForgotPassword
        self.onSignUp = onSignUp
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 48)

                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)

                    VStack(spacing: 4) {
                        Text("Welcome Back!")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)

                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .padding(.top, 20)

                    VStack(alignment: .leading, spacing: 20) {
                        SignInPhoneField(phoneNumber: $phoneNumber)
                        SignInPasswordField(password: $password)

                        Button(action: forgotPassword) {
                            Text("Forgot Password?")
                                .font(.subheadline.bold())
                                .underline()
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        .buttonStyle(.plain)
                        .accessibilityInputLabels(["Forgot Password"])
                    }
                    .padding(.top, 44)

                    Spacer(minLength: 56)

                    PrimaryButton(
                        "Sign In",
                        font: .headline.bold(),
                        height: 48,
                        horizontalPadding: 0,
                        verticalPadding: 0,
                        action: signIn
                    )

                    HStack(spacing: 4) {
                        Text("Don’t have an account?")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)

                        Button(action: signUp) {
                            Text("Sign Up")
                                .font(.subheadline)
                                .underline()
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                        .accessibilityInputLabels(["Sign Up"])
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 40)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)
            .background(Color(.systemBackground))
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

    private func forgotPassword() {
        onForgotPassword()
    }

    private func signUp() {
        onSignUp()
    }
}

private struct SignInPhoneField: View {
    @Binding var phoneNumber: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Phone Number")
                .font(.headline)
                .foregroundStyle(.primary)

            HStack(spacing: 0) {
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.down")
                            .font(.caption.bold())

                        Text("+62")
                            .font(.headline)
                    }
                    .foregroundStyle(.primary)
                    .frame(minWidth: 84, minHeight: 48)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Country code, Indonesia plus sixty two")

                Divider()

                TextField("", text: $phoneNumber)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .accessibilityLabel("Phone Number")
            }
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
    }
}

private struct SignInPasswordField: View {
    @Binding var password: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password")
                .font(.headline)
                .foregroundStyle(.primary)

            SecureField("", text: $password)
                .textContentType(.password)
                .font(.headline)
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .accessibilityLabel("Password")
        }
    }
}


#Preview {
    SignInView()
}
