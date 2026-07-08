//
//  IntroView.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import SwiftUI

struct IntroView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedPage = 0

    let onFinish: () -> Void

    private let pages = [
        IntroPage(imageName: "Intro Phone 1", accessibilityLabel: "Shake your phone to confirm meetups."),
        IntroPage(imageName: "Intro Phone 2", accessibilityLabel: "Find the landmark on the hype radar map."),
        IntroPage(imageName: "Intro Phone 3", accessibilityLabel: "Finish the quest and continue.")
    ]

    init(onFinish: @escaping () -> Void = {}) {
        self.onFinish = onFinish
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TabView(selection: $selectedPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        IntroPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: selectedPage)

                pageIndicator
                    .frame(height: 44)

                continueButton
            }
            .background(Color(.systemBackground))
            .navigationTitle("How to use Lookals")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: backTapped) {
                        Label("", systemImage: "chevron.left")
                    }
                    .accessibilityLabel("Next intro image")
                    .padding()
                    .glassEffect()
                }
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Circle()
                    .fill(index == selectedPage ? Color.primary : Color(.systemGray3))
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(selectedPage + 1) of \(pages.count)")
    }

    private var continueButton: some View {
        LookalsPrimaryButton(
            "Continue",
            accessibilityLabel: selectedPage == pages.count - 1 ? "Finish intro" : "Continue",
            font: .default.weight(.heavy),
            action: continueTapped
        )
        .padding([.horizontal], 16)
    }

    private func continueTapped() {
        if selectedPage == pages.count - 1 {
            onFinish()
        } else {
            swipeImageLeft()
        }
    }

    private func swipeImageLeft() {
        guard selectedPage < pages.count - 1 else { return }

        if reduceMotion {
            selectedPage += 1
        } else {
            withAnimation(.snappy(duration: 0.3)) {
                selectedPage += 1
            }
        }
    }
    
    private func backTapped() {
        swipeImageRight()
    }
    
    private func swipeImageRight() {
        guard selectedPage >= 0 else { return }

        if reduceMotion {
            selectedPage -= 1
        } else {
            withAnimation(.snappy(duration: 0.3)) {
                selectedPage -= 1
            }
        }
    }

}

private struct IntroPage: Identifiable {
    var id: String { imageName }

    let imageName: String
    let accessibilityLabel: String
}

private struct IntroPageView: View {
    let page: IntroPage

    var body: some View {
        GeometryReader { proxy in
            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: proxy.size.width, maxHeight: proxy.size.height)
                .frame(width: proxy.size.width, height: proxy.size.height)
                .accessibilityLabel(page.accessibilityLabel)
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    IntroView()
}
