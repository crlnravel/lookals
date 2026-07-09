//
//  InterestBadge.swift
//  Lookals
//
//  Created by Kevin Halim on 09/07/26.
//

import SwiftUI

struct InterestBadge: View {
    let interest: Interest
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Text(interest.rawValue)
            .font(.system(size: 15, weight: .regular))
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                Capsule().fill(isSelected ? Color.orange.opacity(0.8) : Color.white)
            )
            .overlay(
                Capsule().stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(.black)
            .onTapGesture {
                action()
            }
    }
}

struct InterestSelectionView: View {
    // @Binding lets this component update the data in the parent view
    @Binding var selectedInterests: Set<Interest>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Interests").font(.subheadline).bold()
            
            FlowLayout(spacing: 10) {
                ForEach(Interest.allCases, id: \.self) { interest in
                    let isSelected = selectedInterests.contains(interest)
                    
                    // Here it calls the single button struct we defined above!
                    InterestBadge(
                        interest: interest,
                        isSelected: isSelected
                    ) {
                        // Update the binding when tapped
                        if isSelected {
                            selectedInterests.remove(interest)
                        } else {
                            selectedInterests.insert(interest)
                        }
                    }
                }
            }
        }
    }
}
