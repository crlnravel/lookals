import SwiftUI
import Combine

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
    }
    
    func updateProfile(with draft: User) {
        self.user = draft
    }
}
