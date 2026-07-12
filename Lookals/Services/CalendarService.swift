//
//  CalendarService.swift
//  Lookals
//
//  Created by Gisella Jayata on 10/07/26.
//

import Foundation
import EventKit

final class CalendarService {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()

    private init() {}

    enum CalendarError: LocalizedError {
        case accessDenied
        case saveFailed

        var errorDescription: String? {
            switch self {
            case .accessDenied:
                return "Lookals needs calendar access to add this tour. You can enable it in Settings > Privacy & Security > Calendars."
            case .saveFailed:
                return "Something went wrong while saving the event to your calendar."
            }
        }
    }
    
    func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                return try await eventStore.requestFullAccessToEvents()
            } catch {
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    @discardableResult
    func addTourEvent(
        title: String,
        startDate: Date,
        durationMinutes: Int = 120,
        location: String,
        notes: String? = nil
    ) async throws -> String {
        let granted = await requestAccess()
        guard granted else { throw CalendarError.accessDenied }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = startDate.addingTimeInterval(TimeInterval(durationMinutes * 60))
        event.location = location
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents

        do {
            try eventStore.save(event, span: .thisEvent)
            return event.eventIdentifier
        } catch {
            throw CalendarError.saveFailed
        }
    }
}
