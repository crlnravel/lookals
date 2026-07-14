//
//  LookalsApp.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 30/06/26.
//

import SwiftUI

@main
struct LookalsApp: App {
    private let dependencies = AppDependencies.mock(isStoredInMemoryOnly: false)

    var body: some Scene {
        WindowGroup {
            //ContentView(dependencies: dependencies).preferredColorScheme(.light)
            HomepageView()
        }
    }
}
