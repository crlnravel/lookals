//
//  BSDTourParticipantDisplay.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import SwiftUI

struct BSDTourParticipantDisplay: Identifiable, Equatable {
    let id: String
    let name: String
    let avatarImageName: String?
    let ringColor: Color
    let hasJoined: Bool
}
