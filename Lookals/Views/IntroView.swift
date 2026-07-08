//
//  IntroView.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct IntroView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedPage = 0

    let onBack: () -> Void
    let onFinish: () -> Void

    private let pages = [
        IntroPage(imageName: "Intro Phone 1", accessibilityLabel: "Shake your phone to confirm meetups."),
        IntroPage(imageName: "Intro Phone 2", accessibilityLabel: "Find the landmark on the hype radar map."),
        IntroPage(imageName: "Intro Phone 3", accessibilityLabel: "Finish the quest and continue.")
    ]

    init(
        onBack: @escaping () -> Void = {},
        onFinish: @escaping () -> Void = {}
    ) {
        self.onBack = onBack
        self.onFinish = onFinish
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            TabView(selection: $selectedPage) {
                ForEach(pages.indices, id: \.self) { index in
                    IntroPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: selectedPage)

            pageIndicator
                .padding(.top, 8)
                .padding(.bottom, 48)

            continueButton
                .padding(.horizontal, 16)
                .padding(.bottom, 48)
        }
        .background(Color(.systemBackground))
    }

    private var header: some View {
        ZStack {
            Text("How to use Lookals")
                .font(.title3.weight(.heavy))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 56, height: 56)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel("Back")

                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 24)
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
        Button(action: continueTapped) {
            Text("Continue")
                .font(.title3.weight(.heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
        }
        .background(Color.accentColor, in: Capsule())
        .accessibilityLabel(selectedPage == pages.count - 1 ? "Finish intro" : "Continue")
    }

    private func continueTapped() {
        if selectedPage == pages.count - 1 {
            onFinish()
        } else if reduceMotion {
            selectedPage += 1
        } else {
            withAnimation(.snappy(duration: 0.3)) {
                selectedPage += 1
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
