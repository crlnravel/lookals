//
//  ProfileViewModel.swift
//  Lookals
//
//  Local-first, CloudKit-synced. `localService` is the fast/offline source
//  of truth for immediate reads and writes; `cloudService` is a
//  best-effort sync layer running through the SAME ProfileServicing
//  interface (CloudProfileService), not the old field-by-field
//  CloudKitManager. That old manager encoded profile data into a
//  completely different CKRecord schema than CloudProfileService does —
//  keeping both around would silently write two disconnected copies of
//  the same profile to CloudKit. Don't reintroduce CloudKitManager here.
//

import SwiftUI
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var user: User
    @Published private(set) var profileErrorMessage: String?

    private let localService: any ProfileServicing
    private let cloudService: any ProfileServicing

    convenience init() {
        self.init(
            localService: LocalProfileService.shared,
            cloudService: CloudProfileService.shared
        )
    }

    init(localService: any ProfileServicing, cloudService: any ProfileServicing) {
        self.user = User.olivia
        self.profileErrorMessage = nil
        self.localService = localService
        self.cloudService = cloudService

        Task {
            await loadProfile()
        }
    }

    // MARK: - Public API

    func updateProfile(with draft: User) {
        setUser(draft)
    }

    /// Awaitable version for callers (like EditProfileView) that need to
    /// know when the save has actually finished — e.g. to drive a loading
    /// spinner before dismissing.
    func saveDraft(_ draft: User) async {
        user = draft
        await saveProfile(draft)
    }

    func redeem(_ coupon: Coupon) -> Bool {
        guard user.points >= coupon.pointsRequired else {
            return false
        }

        var updatedUser = user
        updatedUser.points -= coupon.pointsRequired
        updatedUser.myCoupons.append(coupon)
        setUser(updatedUser)
        return true
    }

    func addDebugPoints(_ amount: Int = 50) {
        var updatedUser = user
        updatedUser.points += amount
        updatedUser.exp += amount
        setUser(updatedUser)
    }

    func resetDebugPoints() {
        var updatedUser = user
        updatedUser.points = 0
        setUser(updatedUser)
    }

    // MARK: - Loading

    private func loadProfile() async {
        // Local first: fast, works offline, avoids a blank/placeholder
        // profile flashing while CloudKit is still fetching.
        do {
            if let savedUser = try await localService.loadProfile() {
                user = savedUser
            }
        } catch {
            profileErrorMessage = error.localizedDescription
        }

        // Then overlay with CloudKit if it has a copy — this is what makes
        // profile data follow the user across devices/reinstalls.
        do {
            if let cloudUser = try await cloudService.loadProfile() {
                user = cloudUser
                // Cache it locally so next launch is fast even offline.
                try? await localService.saveProfile(cloudUser)
            }
            profileErrorMessage = nil
        } catch {
            // A CloudKit failure here (e.g. offline, iCloud signed out)
            // shouldn't stomp on a perfectly good local profile or block
            // the UI — just log it and keep using what we already loaded.
            print("CloudKit profile load failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Saving

    private func setUser(_ user: User) {
        self.user = user
        Task {
            await saveProfile(user)
        }
    }

    private func saveProfile(_ user: User) async {
        do {
            try await localService.saveProfile(user)
            profileErrorMessage = nil
        } catch {
            profileErrorMessage = error.localizedDescription
        }

        // Best-effort CloudKit sync. Deliberately not surfaced as
        // `profileErrorMessage` — a local save already succeeded, so a
        // CloudKit hiccup shouldn't look like the whole save failed.
        do {
            try await cloudService.saveProfile(user)
        } catch {
            print("CloudKit profile sync failed: \(error.localizedDescription)")
        }
    }
}
