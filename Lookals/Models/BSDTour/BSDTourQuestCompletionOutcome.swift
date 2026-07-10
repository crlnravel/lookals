//
//  BSDTourQuestCompletionOutcome.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

import Foundation

enum BSDTourQuestCompletionOutcome {
    case showSuccess(title: String, subtitle: String?)
    case waitForGroup(message: String)
}
