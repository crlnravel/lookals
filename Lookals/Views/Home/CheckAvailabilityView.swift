//
//  CheckAvailabilityView.swift
//  Lookals
//
//  Created by Gisella Jayata on 09/07/26.
//

import SwiftUI

struct CheckAvailabilityView: View {
    @ObservedObject var appState: HomeStateManager
    let map: TourMap
    @Binding var path: [HomeRoute]

    @Environment(\.dismiss) private var dismiss

    @State private var localSelectedDate: Date? = nil
    @State private var agreedToTerms = false
    @State private var confirmedAge = false

    @State private var showTerms = false
    @State private var showCancellationPolicy = false
    @State private var showConfirmation = false

    private let saturdays = HomeStateManager.upcomingSaturdays()

    private var canBook: Bool {
        localSelectedDate != nil && agreedToTerms && confirmedAge
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(map.title)
                        .font(.system(size: 32, weight: .heavy))

                    meetingPointSection
                    timeSection
                    dateSection
                    verificationSection
                    bookButton
                }
                .padding(.horizontal, 30)
            }

            if showTerms {
                PolicyPopupView(kind: .terms, isPresented: $showTerms)
                    .zIndex(10)
            }
            if showCancellationPolicy {
                PolicyPopupView(kind: .cancellation, isPresented: $showCancellationPolicy)
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showTerms)
        .animation(.easeInOut(duration: 0.2), value: showCancellationPolicy)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                        .fontWeight(.bold)
                }
            }
            
        }
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(isPresented: $showConfirmation) {
            BookingConfirmationView(appState: appState, map: map, date: localSelectedDate ?? Date()) {
                showConfirmation = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    path.removeAll()
                }
            }
        }
    }

    // MARK: - Sections

    private var meetingPointSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Meeting Point", systemImage: "mappin.and.ellipse")
                .font(.headline)
            Text(map.meetingPoint)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Time", systemImage: "clock")
                .font(.headline)
            Text(map.fixedTime)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Select Date", systemImage: "calendar.badge.plus")
                .font(.headline)

            ForEach(Array(saturdays.enumerated()), id: \.offset) { index, date in
                dateRow(date: date, isFullyBooked: index == 0)
            }
        }
    }

    private func dateRow(date: Date, isFullyBooked: Bool) -> some View {
        let isSelected = localSelectedDate == date

        return Button {
            guard !isFullyBooked else { return }
            localSelectedDate = date
        } label: {
            HStack {
                Text(formatted(date))
                    .foregroundColor(isFullyBooked ? .secondary : .primary)
                Spacer()
                if isFullyBooked {
                    Text("fully booked")
                        .italic()
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Circle()
                        .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1.5)
                        .background(Circle().fill(isSelected ? Color.orange : Color.clear))
                        .frame(width: 22, height: 22)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isFullyBooked ? Color.gray.opacity(0.12) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.orange : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isFullyBooked)
    }

    private var verificationSection: some View {
            VStack(alignment: .leading, spacing: 18) {
                
                checkboxRow(
                    isChecked: $agreedToTerms,
                    label: "I agree to the [Terms & Conditions](tnc) and [Cancellation Policy](cancel)."
                )
                .environment(\.openURL, OpenURLAction { url in
                    if url.absoluteString == "tnc" {
                        withAnimation { showTerms = true }
                        return .handled
                    } else if url.absoluteString == "cancel" {
                        withAnimation { showCancellationPolicy = true }
                        return .handled
                    }
                    return .systemAction
                })

                checkboxRow(
                    isChecked: $confirmedAge,
                    label: "I confirm that I am 18 years of age or older."
                )
            }
        }

        private func checkboxRow(isChecked: Binding<Bool>, label: LocalizedStringKey) -> some View {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    withAnimation {
                        isChecked.wrappedValue.toggle()
                    }
                } label: {
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(Color.black, lineWidth: 1.5)
                        .background(RoundedRectangle(cornerRadius: 4).fill(isChecked.wrappedValue ? Color.black : Color.clear))
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(isChecked.wrappedValue ? 1 : 0)
                        )
                }
                .buttonStyle(.plain)

                Text(label)
                    .font(.subheadline)
                    .tint(.orange)
            }
        }

    private var bookButton: some View {
        Button {
            guard let date = localSelectedDate else { return }
            appState.selectedDate = date
            appState.agreedToTerms = agreedToTerms
            appState.confirmedAge = confirmedAge
            showConfirmation = true
        } label: {
            Text("Book The Date")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canBook ? Color.orange : Color.gray.opacity(0.4))
                .clipShape(Capsule())
        }
        .disabled(!canBook)
        .padding(.top, 70)
    }

    private func formatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: date)
    }
}


#Preview {
    HomepageView()
}
