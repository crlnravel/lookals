//
//  ContentView.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 30/06/26.
//

import SwiftUI

struct ContentView: View {
    @State private var isShowingHome = false

    var body: some View {
        if isShowingHome {
            HomeView()
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
    ContentView()
}
