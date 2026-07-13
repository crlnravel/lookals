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
    @State private var onboardingPath: [OnboardingStep] = []
    @StateObject private var onboardingData = OnboardingData()
    @AppStorage("isSignedIn") private var isSignedIn = false

    var body: some Scene {
        WindowGroup {
            Group {
                if isSignedIn {
                    HomepageView()
                } else {
                    NavigationStack(path: $onboardingPath) {
                        NameInputView(path: $onboardingPath)
                            .navigationDestination(for: OnboardingStep.self) { step in
                                switch step {
                                case .interests:
                                    InterestsView(path: $onboardingPath)
                                case .personality:
                                    PersonalityView(path: $onboardingPath)
                                case .location:
                                    LocationPermissionView(path: $onboardingPath)
                                case .success:
                                    SuccessView(path: $onboardingPath)
                                }
                            }
                    }
                }
            }
            .environmentObject(onboardingData)
            .preferredColorScheme(.light)
        }
    }
}
