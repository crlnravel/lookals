//
//  InterestsView.swift
//  Lookals
//
//  Created by Gisella Jayata on 12/07/26.
//

import SwiftUI

struct LocationPermissionView: View {
    @Binding var path: [OnboardingStep]
    
    // 1. Panggil dismiss untuk menutup seluruh layar onboarding (fullScreenCover)
    @Environment(\.dismiss) private var dismiss
    
    // 2. Akses variabel global untuk membuka "kunci" aplikasi
    @AppStorage("isSignedIn") private var isSignedIn = false
    
    var body: some View {
        OnboardingTemplate(
            title: "The city stays dark until you drop a pin.",
            subtitle: "Grant location access to unlock the map and find tours near you.",
            bgImageName: "asset-pin",
            bgImageSize: 190,
            onBack: { path.removeLast() },
            circleYOffset: 240
        ) {
            VStack(spacing: 16) {
                Button {
                    // TODO: Tambahkan logika memanggil CoreLocation (jika ada)
                    
                    completeOnboarding()
                } label: {
                    PrimaryButtonLabel(title: "Turn on location")
                }
                
                Button {
                    completeOnboarding()
                } label: {
                    Text("Not now")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
        }
    }
    
    private func completeOnboarding() {
        isSignedIn = true
    }
}

#Preview {
    LocationPermissionView(path: .constant([]))
}
