//
//  InterestsView.swift
//  Lookals
//
//  Created by Gisella Jayata on 12/07/26.
//


import SwiftUI

struct InterestsView: View {
    @Binding var path: [OnboardingStep]
    @State private var selectedInterests: Set<String> = []
    @EnvironmentObject var onboardingData: OnboardingData
    
    let allInterests = [
        "☕️ Coffee & Tea", "📸 Photography",
        "🎬 Movies", "🏋️ Workout", "🎶 Music",
        "🎨 Art", "🎮 Game", "🌿 Nature"
    ]
    
    var body: some View {
        OnboardingTemplate(
            title: "What are your interests?",
            subtitle: "Choose as many as you like",
            bgImageName: "profileSetupBg",
            onBack: { path.removeLast() }
        ) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 12)], spacing: 12) {
                ForEach(allInterests, id: \.self) { interest in
                    let isSelected = selectedInterests.contains(interest)
                    
                    Text(interest)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .black)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.orange : Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                        )
                        .overlay(
                            Capsule().stroke(Color.gray.opacity(0.2), lineWidth: isSelected ? 0 : 1)
                        )
                        .onTapGesture {
                            if isSelected {
                                selectedInterests.remove(interest)
                            } else {
                                selectedInterests.insert(interest)
                            }
                        }
                }
            }
            .padding(.bottom, 30)
            
            Button {
                onboardingData.interests = Array(selectedInterests)
                path.append(.personality)
            } label: {
                PrimaryButtonLabel(title: "Next")
            }
        }
    }
}

#Preview {
    NavigationStack {
        InterestsView(path: .constant([]))
    }
    
}
