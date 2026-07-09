//
//  DummyUserData.swift
//  Lookals
//
//  Created by Kevin Halim on 08/07/26.
//

import Foundation

enum Gender: String, CaseIterable {
    case female = "Female"
    case male = "Male"
    case preferNotToSay = "Prefer not to say"
}

enum Personality: String, CaseIterable {
    case introverted = "Introverted"
    case extroverted = "Extroverted"
    case ambiverted = "Ambiverted"
}

enum UserLevel: Int {
    case level1 = 1, level2, level3, level4
    
    var title: String {
        switch self {
        case .level1: return "The Newcomer"
        case .level2: return "The Explorer"
        case .level3: return "The Enthusiast"
        case .level4: return "The Master"
        }
    }
}

enum Interest: String, CaseIterable {
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
struct User {
    var fullName: String
    var nickname: String
    var phoneNumber: String
    var gender: Gender
    var personality: Personality
    var interests: Set<Interest>
    var points: Int
    var profileImageName: String
    var myCoupons: [Coupon] = [] // NEW: Stores the user's coupons
    
    // save image when user upload photo
    var customImageData: Data? = nil
    
    var level: UserLevel {
        if points < 100 { return .level1 }
        else if points < 300 { return .level2 }
        else if points < 600 { return .level3 }
        else { return .level4 }
    }
}

// MARK: - Dummy Data
extension User {
    static let olivia = User(
        fullName: "Olivia Olivia",
        nickname: "Olivia",
        phoneNumber: "+62 812-3456-7890",
        gender: .female,
        personality: .extroverted,
        interests: [.coffeeTea, .photography, .game],
        points: 0,
        profileImageName: "Profile Picture",
        myCoupons: []
    )
}
