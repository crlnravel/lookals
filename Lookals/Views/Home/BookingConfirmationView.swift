//
//  BookingConfirmationView.swift
//  Lookals
//

import SwiftUI

struct BookingConfirmationView: View {
    @ObservedObject var appState: HomeStateManager
    let map: TourMap
    let date: Date
    var onBackToHome: () -> Void

    private enum CalendarStatus {
        case adding
        case success
        case failure(String)
    }

    @State private var calendarStatus: CalendarStatus = .adding
    @State private var isConfettiActive = true

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            if isConfettiActive {
                ConfettiView(isActive: $isConfettiActive)
            }

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
                .padding()
                .background(RoundedRectangle(cornerRadius: 24).fill(Color(.systemGray6)))
                .padding(.horizontal)

                calendarStatusRow
                    .padding(.horizontal)

                Spacer()

                Button {
                    isConfettiActive = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        appState.confirmBooking(mapId: map.id, date: date)
                        onBackToHome()
                    }
                } label: {
                    Text("Back to Home")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .clipShape(Capsule())
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .task {
            await addToCalendar()
        }
    }

    // MARK: - Calendar Status Row

    @ViewBuilder
    private var calendarStatusRow: some View {
        HStack(spacing: 8) {
            switch calendarStatus {
            case .adding:
                ProgressView()
                    .tint(.secondary)
                Text("Adding to your calendar...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

            case .success:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Added to your calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

            case .failure:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                Text("Couldn't add to calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button("Retry") {
                    Task { await addToCalendar() }
                }
                .font(.subheadline.bold())
                .foregroundColor(.orange)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func addToCalendar() async {
        calendarStatus = .adding

        guard let startDate = combinedStartDate() else {
            calendarStatus = .failure("Couldn't determine the tour's start time.")
            return
        }

        do {
            try await CalendarService.shared.addTourEvent(
                title: map.title,
                startDate: startDate,
                location: map.meetingPoint,
                notes: "Booked via Lookals · \(map.priceText) · \(map.capacity) person capacity"
            )
            await MainActor.run {
                calendarStatus = .success
            }
        } catch {
            await MainActor.run {
                calendarStatus = .failure(error.localizedDescription)
            }
        }
    }

    /// Combines `date` (the selected Saturday, time-of-day irrelevant) with
    /// `map.fixedTime` (a "HH.mm" string like "14.00") into one Date.
    private func combinedStartDate() -> Date? {
        let components = map.fixedTime
            .split(separator: ".")
            .compactMap { Int($0) }

        guard components.count == 2 else { return date }

        var calendarComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        calendarComponents.hour = components[0]
        calendarComponents.minute = components[1]

        return Calendar.current.date(from: calendarComponents)
    }

    // MARK: - Helpers

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
