//
//  TourDetailsPopup.swift
//  Lookals
//
//  Created by Gisella Jayata on 09/07/26.
//

import SwiftUI

struct TourDetailsPopup: View {
    @ObservedObject var appState: HomeStateManager
    let map: TourMap
    @Binding var isPresented: Bool
    @Binding var path: [HomeRoute]

    @State private var showCancelAlert = false
    
    @Binding var showSignIn: Bool
    @AppStorage("isSignedIn") private var isSignedIn = false
    
    private var isBookedMap: Bool {
        map.id == appState.bookedMapId
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }

            VStack(alignment: .leading, spacing: 0) {
                headerImage
                content
            }
            .background(Color(UIColor.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 38))
            .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .zIndex(100)
        .alert("Are you sure?", isPresented: $showCancelAlert) {
            Button("Cancel Tour", role: .destructive) {
                appState.cancelBooking()
                isPresented = false
            }
            Button("Keep Booking", role: .cancel) {}
        } message: {
            Text("This will cancel your upcoming tour and release your spot.")
        }
    }

    // MARK: - Header
    private var headerImage: some View {
        ZStack(alignment: .top) {

            Image(map.image)
                .resizable()
                .scaledToFill()
                .frame(height: 220)
                .clipped()
                

            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            isPresented = false
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(width: 44, height: 44)
                            .background(.regularMaterial, in: Circle())
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.orange)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .stroke(Color.orange, lineWidth: 10)
                            )
                            .padding(.bottom, 7)
                        Text("\(map.pointCost)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                        Text("Points")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                }
                .padding(30)

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Text(map.title)
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(map.subtitleTags.joined(separator: " · "))
                        .font(.subheadline.bold())
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 35)
                .padding(.bottom, 20)
            }
        }
        .frame(height: 220)
    }

    // MARK: - Content
    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(map.summary)
                .font(.subheadline)
                .foregroundColor(.primary)
                .lineSpacing(4)

            if isBookedMap, let date = appState.selectedDate, appState.bookingStatus != .unbooked {
                bookedInfoBlock(date: date)
            }

            VStack(spacing: 12) {
                statRow(icon: "map", text: "\(map.quests) Quests")
                statRow(icon: "mappin.and.ellipse", text: "\(map.landmarks) Landmarks")
                statRow(icon: "clock", text: map.duration)
                statRow(icon: "dollarsign.circle", text: map.priceText)
                statRow(icon: "person.2", text: "\(map.capacity) Person")
            }

            actionButton
                .padding(.top, 4)
        }
        .padding(35)
    }

    private func bookedInfoBlock(date: Date) -> some View {
        HStack(spacing: 16) {
            Label(formatted(date), systemImage: "calendar")
            Label(map.fixedTime, systemImage: "clock")
        }
        .font(.subheadline.bold())
        .foregroundColor(.orange)
    }

    private func statRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Label(text, systemImage: icon)
                .fontWeight(.semibold)
            Spacer()
        }
    }

    @ViewBuilder
        private var actionButton: some View {
            if isBookedMap && appState.bookingStatus == .upcoming {
                Button {
                    isPresented = false
                } label: {
                    actionLabel("Cancel Tour", background: Color.orange, foreground: .white)
                }
            } else if isBookedMap && appState.bookingStatus == .ongoing {
                actionLabel("Tour in Progress", background: Color.orange.opacity(0.6), foreground: .white)
            } else if map.isAvailable {
                Button {
                    if isSignedIn {
                        isPresented = false
                        path.append(HomeRoute.checkAvailability(map))
                    } else {
                        showSignIn = true
                    }
                } label: {
                    actionLabel("Check Availability", background: Color.orange, foreground: .white)
                }
            } else {
                actionLabel("Coming Soon", background: Color.gray.opacity(0.4), foreground: .white.opacity(0.7))
            }
        }

    private func actionLabel(_ title: String, background: Color, foreground: Color) -> some View {
        Text(title)
            .font(.headline.bold())
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(background)
            .clipShape(Capsule())
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }
}
