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
                onSignIn: showHome
            )
        case .intro:
            IntroView(onFinish: showFaceVerification)
        case .faceVerification:
            FaceVerificationView(
                onBack: showIntro,
                onDone: showBSDTour
            )
        case .home:
            HomeView(dependencies: dependencies)
        case .bsdTour:
            BSDTourMapView(dependencies: dependencies, onBack: showHome)
        }
    }

    private func showIntro() {
        screen = .intro
    }

    private func showFaceVerification() {
        screen = .faceVerification
    }

    private func showHome() {
        screen = .home
    }

    private func showBSDTour() {
        screen = .bsdTour
    }
}

private enum AppScreen {
    case login
    case intro
    case faceVerification
    case home
    case bsdTour
}

#Preview {
    ContentView(dependencies: .preview)
}
