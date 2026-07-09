//
//  OngoingQuestInputMode.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 10/07/26.
//

enum OngoingQuestInputMode: Equatable {
    case text
    case currency

    var placeholder: String {
        switch self {
        case .text:
            ""
        case .currency:
            "Rp"
        }
    }
}
