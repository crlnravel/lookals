//
//  BookingConfirmationView.swift
//  Lookals
//
//  Created by Gisella Jayata on 09/07/26.
//

import SwiftUI

struct BookingConfirmationView: View {
    @ObservedObject var appState: HomeStateManager
    let map: TourMap
    let date: Date
    var onBackToHome: () -> Void

    var body: some View {
        ZStack {
            // Background Layer
            Color(.systemBackground).ignoresSafeArea()
            ConfettiView()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 4) {
                    Text("Date Reserved")
                        .font(.title2.bold())
                    Text("See You There!")
                        .font(.system(size: 34, weight: .heavy))
                }
                .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 18) {
                    Text(map.title)
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, alignment: .center)

                    detailRow(icon: "mappin.and.ellipse", text: map.meetingPoint)
                    detailRow(icon: "clock", text: map.fixedTime)
                    detailRow(icon: "calendar.badge.plus", text: formatted(date))
                }
                .padding(24)
                
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 38))
                .overlay(
                    RoundedRectangle(cornerRadius: 38)
                        .strokeBorder(Color.white.opacity(0.6), lineWidth: 2)
                )
                .padding(.horizontal, 24)

                Spacer()

                // MARK: - Bottom Button
                Button {
                    appState.confirmBooking(mapId: map.id, date: date)
                    onBackToHome()
                } label: {
                    Text("Back to Home")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func detailRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: date)
    }
}
