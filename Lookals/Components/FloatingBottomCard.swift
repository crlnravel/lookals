//
//  FloatingBottomCard.swift
//  Lookals
//
//  Created by Gisella Jayata on 09/07/26.
//

import SwiftUI

struct FloatingBottomCard: View {
    @ObservedObject var appState: HomeStateManager
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(statusLabel)
                        .font(.subheadline.bold())
                        .foregroundColor(.orange)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                    
                }

                Text(appState.bookedMap?.title ?? "")
                    .font(.title2.bold())
                    .foregroundColor(.primary)

                if appState.bookingStatus == .upcoming, let map = appState.bookedMap {
                    HStack(spacing: 10) {
                        Text(formattedDate)
                        Image(systemName: "clock")
                        Text(map.fixedTime)
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                } else if appState.bookingStatus == .ongoing {
                    RouteTrackerView()
                }
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 38).fill(Color.white))
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }

    private var statusLabel: String {
        appState.bookingStatus == .ongoing ? "Ongoing" : "Up coming"
    }

    private var formattedDate: String {
        guard let date = appState.selectedDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}

struct RouteTrackerView: View {
    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Circle()
                    .stroke(Color.orange, lineWidth: 1.5)
                    .frame(width: 28, height: 28)
                
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 12))
                    .foregroundColor(.orange)
            }
            
            ForEach(1...3, id: \.self) { i in
                
                Rectangle()
                    .fill(Color.primary)
                    .frame(height: 1)
                    .padding(.horizontal, 10)
                
                HStack(spacing: 4) {
                    Text("\(i)")
                        .font(.system(size: 20, weight: .bold))
                    
                    Image(systemName: "map") 
                        .font(.system(size: 18, weight: .regular))
                }
                .foregroundColor(.primary)
            }
        }
        .padding(.top, 4)
    }
}

#Preview {
    let state = HomeStateManager()
    return FloatingBottomCard(appState: state) {}
}
