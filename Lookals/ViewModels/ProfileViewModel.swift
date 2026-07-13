import SwiftUI
import Combine

<<<<<<< HEAD
class ProfileViewModel: ObservableObject {
    @Published var user: User
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.user = User()
        
        loadFromCloudKit()
    }
    
    func loadFromCloudKit() {
        CloudKitManager.shared.fetchUserProfile()
 
        CloudKitManager.shared.$fetchedName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                if !name.isEmpty && name != "Unknown" {
                    self?.user.nickname = name
                }
            }
            .store(in: &cancellables)
        
        CloudKitManager.shared.$fetchedInterests
            .receive(on: DispatchQueue.main)
            .sink { [weak self] array in
                let interestSet = Set(array.compactMap { Interest(rawValue: $0) })
                if !interestSet.isEmpty {
                    self?.user.interests = interestSet
                }
            }
            .store(in: &cancellables)

        CloudKitManager.shared.$fetchedProfileImageData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                if let data = data {
                    self?.user.customImageData = data
                }
            }
            .store(in: &cancellables)
=======
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
>>>>>>> a470c85cf9d0b6e7d95d03e5e19cc39e48d21e88
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
