//
//  ContentView.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 30/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var screen: AppScreen = .login

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .preview) {
        self.dependencies = dependencies
    }

    var body: some View {
        switch screen {
        case .login:
            LoginView(
                onGetStarted: showIntro,
                onSignIn: showSignIn
            )
        case .signIn:
            SignInView(
                onBack: showLogin,
                onSignIn: showHome,
                onSignUp: showIntro
            )
        case .intro:
            IntroView(onFinish: showHome)
        case .home:
            HomeView(dependencies: dependencies)
        }
    }

    private func showIntro() {
        screen = .intro
    }

    private func showSignIn() {
        screen = .signIn
    }

    private func showLogin() {
        screen = .login
    }

    private func showHome() {
        screen = .home
    }
}

private enum AppScreen {
    case login
    case signIn
    case intro
    case home
}

#Preview {
    ContentView(dependencies: .preview)
}
