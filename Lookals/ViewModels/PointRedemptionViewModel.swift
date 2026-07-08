//
//  PointRedemptionViewModel.swift
//  Lookals
//
//  Created by Kevin Halim on 08/07/26.
//

import SwiftUI
import Combine

enum PointRedemptionTab {
    case available
    case myCoupons
}

enum RedemptionAlert: Identifiable {
    case success(Coupon)
    case insufficient
    
    var id: String {
        switch self {
        case .success(let coupon): return "success_\(coupon.id)"
        case .insufficient: return "insufficient"
        }
    }
}

class PointRedemptionViewModel: ObservableObject {
    // 1. UI State
    @Published var selectedTab: PointRedemptionTab = .available
    @Published var activeAlert: RedemptionAlert? = nil
    @Published var selectedCouponForOverlay: Coupon? = nil
    
    // 2. Dependency Injection (Connects to the main user data)
    private var profileViewModel: ProfileViewModel
    
    init(profileViewModel: ProfileViewModel) {
        self.profileViewModel = profileViewModel
    }
        
    func attemptRedemption(for coupon: Coupon) {
        if profileViewModel.user.points >= coupon.pointsRequired {
            profileViewModel.user.points -= coupon.pointsRequired
            profileViewModel.user.myCoupons.append(coupon)
            activeAlert = .success(coupon)
        } else {
            activeAlert = .insufficient
        }
    }
        
    func addDebugPoints() { profileViewModel.user.points += 50 }
    func resetDebugPoints() { profileViewModel.user.points = 0 }
        
    func alertTitle() -> String {
        switch activeAlert {
        case .success: return "Redemption Successful!"
        case .insufficient: return "Not Enough Points"
        case nil: return ""
        }
    }
    
    func alertMessage() -> String {
        switch activeAlert {
        case .success: return "You have successfully redeemed this coupon."
        case .insufficient: return "You don't have enough points to redeem this coupon."
        case nil: return ""
        }
    }
}
