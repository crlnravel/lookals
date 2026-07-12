//
//  ProfileViewModel.swift
//  Lookals
//
//  Created by Kevin Halim on 08/07/26.
//

import SwiftUI
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var user: User
    @Published private(set) var profileErrorMessage: String?

    private let profileService: any ProfileServicing
    
    convenience init() {
        self.init(profileService: LocalProfileService.shared)
    }

    init(profileService: any ProfileServicing) {
        self.user = User.olivia
        self.profileErrorMessage = nil
        self.profileService = profileService

        Task {
            await loadProfile()
        }
    }
    
    func updateProfile(with draft: User) {
        setUser(draft)
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

    private func loadProfile() async {
        do {
            if let savedUser = try await profileService.loadProfile() {
                user = savedUser
            }
            profileErrorMessage = nil
        } catch {
            profileErrorMessage = error.localizedDescription
        }
    }

    private func setUser(_ user: User) {
        self.user = user
        Task {
            await saveProfile(user)
        }
    }

    private func saveProfile(_ user: User) async {
        do {
            try await profileService.saveProfile(user)
            profileErrorMessage = nil
        } catch {
            profileErrorMessage = error.localizedDescription
        }
    }
}
