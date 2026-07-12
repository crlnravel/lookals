//
//  HomeStateManager.swift
//  Lookals
//
//  Created by Gisella Jayata on 09/07/26.
//
//

import Foundation
import Combine
import SwiftUI

final class HomeStateManager: ObservableObject {
    
    @Published var hasCompletedTour: Bool = false {
        didSet { persist() }
    }
    
    @Published var completedMapIds: [UUID] = [] {
        didSet { persist() }
    }

    // MARK: - Core State

    @Published var bookingStatus: MapBookingStatus = .unbooked {
        didSet { persist() }
    }
    @Published var bookedMapId: UUID? = nil {
        didSet { persist() }
    }
    @Published var selectedDate: Date? = nil {
        didSet { persist() }
    }

    // MARK: - Verification / T&C

    @Published var agreedToTerms: Bool = false
    @Published var confirmedAge: Bool = false

    // MARK: - Data Source

    @Published var maps: [TourMap] = TourMap.sampleData

    // MARK: - Derived Helpers

    var bookedMap: TourMap? {
        guard let id = bookedMapId else { return nil }
        return maps.first(where: { $0.id == id })
    }

    var canBook: Bool {
        selectedDate != nil && agreedToTerms && confirmedAge
    }

    // MARK: - Init

    init() {
        restore()
    }
    
    func finishTour() {
        withAnimation {
            if let currentMapId = self.bookedMapId {
                if !self.completedMapIds.contains(currentMapId) {
                    self.completedMapIds.append(currentMapId)
                }
            }
            
            self.bookingStatus = .unbooked
            self.bookedMapId = nil
            self.selectedDate = nil
            
            self.hasCompletedTour = true
        }
    }

    // MARK: - State Transitions

    func confirmBooking(mapId: UUID, date: Date) {
        bookedMapId = mapId
        selectedDate = date
        bookingStatus = .upcoming
    }

    func cancelBooking() {
        bookedMapId = nil
        selectedDate = nil
        bookingStatus = .unbooked
        resetVerification()
    }

    func resetVerification() {
        agreedToTerms = false
        confirmedAge = false
    }

    func triggerDDay() {
        guard bookingStatus == .upcoming else { return }
        bookingStatus = .ongoing
    }

    func revertToUpcoming() {
        guard bookingStatus == .ongoing else { return }
        bookingStatus = .upcoming
    }

    // MARK: - Date Math
    static func upcomingSaturdays(from referenceDate: Date = Date(), count: Int = 3) -> [Date] {
        let calendar = Calendar.current
        guard let threeWeeksOut = calendar.date(byAdding: .day, value: 0, to: referenceDate) else { return [] }

        let weekday = calendar.component(.weekday, from: threeWeeksOut)
        let daysUntilSaturday = (7 - weekday + 7) % 7

        guard let firstSaturday = calendar.date(byAdding: .day, value: daysUntilSaturday, to: threeWeeksOut) else { return [] }

        return (0..<count).compactMap { offset in
            calendar.date(byAdding: .day, value: offset * 7, to: firstSaturday)
        }
    }

    // MARK: - Persistence

    private struct BookingSnapshot: Codable {
        var bookingStatus: MapBookingStatus
        var bookedMapId: UUID?
        var selectedDate: Date?
        var hasCompletedTour: Bool?
        var completedMapIds: [UUID]?
    }

    private let defaultsKey = "com.lookals.bookingSnapshot"
    private var isRestoring = false

    private func persist() {
        guard !isRestoring else { return }

        let snapshot = BookingSnapshot(
            bookingStatus: bookingStatus,
            bookedMapId: bookedMapId,
            selectedDate: selectedDate,
            hasCompletedTour: hasCompletedTour,
            completedMapIds: completedMapIds
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func restore() {
        guard
            let data = UserDefaults.standard.data(forKey: defaultsKey),
            let snapshot = try? JSONDecoder().decode(BookingSnapshot.self, from: data)
        else { return }

        isRestoring = true
        bookingStatus = snapshot.bookingStatus
        bookedMapId = snapshot.bookedMapId
        selectedDate = snapshot.selectedDate
        
        hasCompletedTour = snapshot.hasCompletedTour ?? false
        completedMapIds = snapshot.completedMapIds ?? []
        
        isRestoring = false
    }
}
