//
//  ContentView.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 30/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var isShowingHome = false

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .preview) {
        self.dependencies = dependencies
    }

    var body: some View {
        if isShowingHome {
            HomeView(dependencies: dependencies)
        } else {
            LoginView(
                onGetStarted: showHome,
                onSignIn: showHome
            )
        }
    }

    private func showHome() {
        isShowingHome = true
    }
}

#Preview {
    ContentView(dependencies: .preview)
}
