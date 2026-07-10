//
//  HistoryView.swift
//  Lookals
//
//  Created by Kevin Halim on 08/07/26.
//


import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Spacer()
            
            // Empty State Text
            Text("You haven't joined any\ntour yet.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            Spacer()
        }
        // Native Navigation Modifiers
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}
