//
//  LocationPermissionView.swift
//  Lookals
//
//  Created by Gisella Jayata on 12/07/26.
//


import SwiftUI

struct LocationPermissionView: View {
    @Binding var path: [OnboardingStep]
    
    var body: some View {
        OnboardingTemplate(
            title: "The city stays dark until you drop a pin.",
            subtitle: "Grant location access to unlock the map and find your potential Lookals connection.",
            bgImageName: "asset-pin",
            bgImageSize: 200,
            onBack: { path.removeLast() },
            circleYOffset: 270,
        ) {
            VStack(spacing: 16) {
                Button {
                    // Trigger LocationManager request here
                    path.append(.success)
                } label: {
                    PrimaryButtonLabel(title: "Turn on location")
                }
                
                Button {
                    path.append(.success)
                } label: {
                    Text("Not now")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LocationPermissionView(path: .constant([]))
    }
   
}
