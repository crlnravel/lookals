//
//  ProfileViewModel.swift
//  Lookals
//
//  Created by Kevin Halim on 08/07/26.
//

import SwiftUI
import Combine

class ProfileViewModel: ObservableObject {
    @Published var user: User
    
    init() {
        self.user = User.olivia
    }
    
    func updateProfile(with draft: User) {
        self.user = draft
    }
}
