//
//  DummyUserData.swift
//  Lookals
//
//  Created by Kevin Halim on 08/07/26.
//

import Foundation

nonisolated enum Gender: String, CaseIterable, Codable, Sendable {
    case female = "Female"
    case male = "Male"
    case preferNotToSay = "Prefer not to say"
}

nonisolated enum Personality: String, CaseIterable, Codable, Sendable {
    case introverted = "Introverted"
    case extroverted = "Extroverted"
    case ambiverted = "Ambiverted"
}

nonisolated enum UserLevel: Int, Codable, Sendable {
    case level1 = 1, level2, level3, level4
    
    var title: String {
        switch self {
        case .level1: return "Newcomer"
        case .level2: return "Explorer"
        case .level3: return "Regular"
        case .level4: return "Lookals"
        }
    }
    
    var badgeImageName: String {
        switch self {
        case .level1: return "Newcomer"
        case .level2: return "Explorer"
        case .level3: return "Regular"
        case .level4: return "Lookal"
        }
    }
}

nonisolated enum Interest: String, CaseIterable, Codable, Sendable {
    case coffeeTea = "☕️ Coffee & Tea"
    case photography = "📸 Photography"
    case movies = "🎬 Movies"
    case workout = "🏋️ Workout"
    case music = "🎶 Music"
    case art = "🎨 Art"
    case game = "🎮 Game"
    case nature = "🌿 Nature"
}

// MARK: - User Model
nonisolated struct User: Codable, Sendable {
    var fullName: String
    var nickname: String
    var phoneNumber: String
    var gender: Gender
    var personality: Personality
    var interests: Set<Interest>
    
    var exp: Int      // exp buat badge
    var points: Int   // point buat coupon
    
    var profileImageName: String
    var myCoupons: [Coupon] = []
    
    // save image when user upload photo
    var customImageData: Data? = nil
    
    var level: UserLevel {
        if exp < 200 { return .level1 }
        else if exp < 400 { return .level2 }
        else if exp < 600 { return .level3 }
        else { return .level4 }
    }
    
    init() {
            self.fullName = ""
            self.nickname = ""
            self.phoneNumber = ""
            self.gender = .female // Nilai default
            self.personality = .introverted // Nilai default
            self.interests = []
            self.exp = 0
            self.points = 0
            self.profileImageName = "Profile Picture"
            self.myCoupons = []
        }
}
