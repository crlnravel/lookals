//
//  PolicyPopupView.swift
//  Lookals
//
//  Created by Gisella Jayata on 09/07/26.
//

import SwiftUI

struct PolicyPopupView: View {
    enum Kind {
        case terms
        case cancellation

        var title: String {
            switch self {
            case .terms: return "Terms & Conditions"
            case .cancellation: return "Cancellation Policy"
            }
        }

        var body: String {
            switch self {
            case .terms:
                return """
                    Lookals acts solely as an intermediary booking platform connecting users with independent tour organizers. We do not directly operate or manage the tours.

                    As a platform provider, Lookals is not liable for any personal injury, property damage, loss, or disputes that occur during the tour. Full operational and safety responsibility lies with the participants.

                    Booking a slot is free of charge. However, all expenses incurred during the tour (including but not limited to transportation, meals, and entrance fees) are strictly personal expenses. Confirmed slots are tied to your account and are strictly non-transferable.
                    """
            case .cancellation:
                return """
                If you are unable to attend, you must cancel your booking through the app at least 2 days prior to the scheduled start time.

                As slots are free and limited, early cancellation allows us to reallocate your spot to other.

                Failing to cancel within the required timeframe, or failing to attend the scheduled tour (No-Show), will be recorded by the system. Repeated offenses may result in temporary restrictions or permanent suspension of your account's booking privileges.
                """
            }
        }
    }

    let kind: Kind
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                }

            VStack(spacing: 24) {
                Text(kind.title)
                    .font(.system(size: 24, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .padding(.top, 28)
                    .padding(.horizontal)

                ScrollView {
                    Text(kind.body)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.horizontal)
                }
                .frame(maxHeight: 350)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPresented = false
                    }
                } label: {
                    Text("I Understand")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .clipShape(Capsule())
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 38, style: .continuous))
            .padding(.horizontal, 36)
            .shadow(radius: 20)
            .transition(.scale.combined(with: .opacity))
            .padding(.bottom, 100)
        }
    }
}

#Preview {
    HomepageView()
}
