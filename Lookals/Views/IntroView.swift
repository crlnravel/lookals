//
//  IntroView.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//  izin timpa -zee

import SwiftUI

struct IntroView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedPage = 0

    let onFinish: () -> Void

    private let pages = [
        IntroPage(
            title: "This city is full of people,\nyet it's still a stranger to you?",
            pageNum: "1",
            mainImageName: "intro-asset-1",
            backgroundImageName: "crowdImage",
            backgroundColor: .black,
            hasCurvedBottom: true,
            buttonText: "Continue",
            buttonColor: nil,
            buttonTextColor: nil,
            accessibilityLabel: "This city is full of people, yet it's still a stranger to you?"
        ),
        IntroPage(
            title: "You sleep here,\nyet you remain an outsider.",
            pageNum: "2",
            mainImageName: nil,
            backgroundImageName: nil,
            backgroundColor: .black,
            hasCurvedBottom: false,
            buttonText: "Continue",
            buttonColor: nil,
            buttonTextColor: nil,
            accessibilityLabel: "You sleep here, yet you remain an outsider."
        ),
        IntroPage(
            title: "This city has a version of\nitself you've never seen.",
            pageNum: "3",
            mainImageName: "intro-asset-2",
            backgroundImageName: nil,
            backgroundColor: .black,
            hasCurvedBottom: false,
            buttonText: "Continue",
            buttonColor: nil,
            buttonTextColor: nil,
            accessibilityLabel: "This city has a version of itself you've never seen."
        ),
        IntroPage(
            title: "Best stories aren't solo ones.\n5 strangers. One map.",
            pageNum: "4",
            mainImageName: "intro-asset-3",
            backgroundImageName: nil,
            backgroundColor: .accentColor,
            hasCurvedBottom: true,
            buttonText: "Continue",
            buttonColor: nil,
            buttonTextColor: nil,
            accessibilityLabel: "Best stories aren't solo ones. 5 strangers. One map."
        ),
        IntroPage(
            title: "Pick a time.\nWe planned the rest.",
            pageNum: "5",
            mainImageName: "intro-asset-4",
            backgroundImageName: nil,
            backgroundColor: .accentColor,
            hasCurvedBottom: false,
            buttonText: "Start Exploring",
            buttonColor: .black,
            buttonTextColor: .white,
            accessibilityLabel: "Pick a time.\nWe planned the rest."
        )
    ]
    
    init(onFinish: @escaping () -> Void = {}) {
        self.onFinish = onFinish
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ZStack {
                    IntroPageView(page: pages[selectedPage])
                        .id(selectedPage)
                }
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onEnded { value in
                            if value.translation.width < -50 {
                                swipeImageLeft()
                            } else if value.translation.width > 50 {
                                swipeImageRight()
                            }
                        }
                )
                
                VStack(spacing: 20) {
                    Spacer()
                    pageIndicator
                        .frame(height: 50)

                    continueButton
                        .padding(.bottom, 16)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: backTapped) {
                        Label("", systemImage: "chevron.left")
                    }
                    .accessibilityLabel("Previous intro image")
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
                    .fill(index == selectedPage ? Color(.systemGray) : Color(.systemGray5))
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(selectedPage + 1) of \(pages.count)")
    }

    private var continueButton: some View {
        ButtonColor(
            selectedPage == pages.count - 1 ? "Start Exploring" : "Continue",
            accessibilityLabel: selectedPage == pages.count - 1 ? "Finish intro" : "Continue",
            font: .default.weight(.heavy),
            buttonColor: selectedPage == pages.count - 1 ? .black : .accent,
            textColor: .white,
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
            withAnimation(.easeInOut(duration: 0.4)) {
                selectedPage += 1
            }
        }
    }
    
    private func backTapped() {
        swipeImageRight()
    }
    
    private func swipeImageRight() {
        guard selectedPage > 0 else { return }

        if reduceMotion {
            selectedPage -= 1
        } else {
            withAnimation(.easeInOut(duration: 0.4)) {
                selectedPage -= 1
            }
        }
    }
}

private struct IntroPage: Identifiable {
    let id = UUID()
    let title: String
    let pageNum: String
    let mainImageName: String?
    let backgroundImageName: String?
    let backgroundColor: Color
    let hasCurvedBottom: Bool
    let buttonText: String
    let buttonColor: Color?
    let buttonTextColor: Color?
    let accessibilityLabel: String
}

private struct IntroPageView: View {
    let page: IntroPage
    
    var body: some View {
        ZStack {
            page.backgroundColor
                .ignoresSafeArea()
                .transition(.opacity)
            
            if let bgImage = page.backgroundImageName {
                    Image(bgImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: .infinity, alignment: .top)
                        .ignoresSafeArea()
                        .transition(.opacity)
            }
            
            if page.hasCurvedBottom {
                VStack {
                    Spacer()
                    if page.hasCurvedBottom {
                        Color.clear
                        .ignoresSafeArea()
                        .overlay(alignment: .bottom) {
                            if page.pageNum == "1" {
                                Ellipse()
                                    .fill(Color.white)
                                    .frame(width: 900, height: 900)
                                    .offset(y: 415)
                                    .transition(.move(edge: .bottom))
                            }
                            else if page.pageNum == "4" {
                                Ellipse()
                                    .fill(Color.white)
                                    .frame(width: 900, height: 900)
                                    .offset(y: 525)
                                    .transition(.move(edge: .top))
                            }
                        }
                    }
                }
                .ignoresSafeArea()
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                if let mainImage = page.mainImageName {
                    if page.pageNum == "1" {
                        Image(mainImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 220)
                            .offset(y: 85)
                            .transition(.move(edge: .bottom))
                    }
                    else if page.pageNum == "3" {
                        Image(mainImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 260)
                            .padding(.trailing, 20)
                            .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .bottom)))
                    }
                    else if page.pageNum == "4" {
                        Image(mainImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 350)
                            .offset(y: -20)
                            .transition(.move(edge: .top))
                    }
                    else if page.pageNum == "5" {
                        Image(mainImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 320)
                            .offset(y: 90)
                            .transition(.move(edge: .bottom))
                    }
                }
                
                if page.pageNum == "1" {
                    Text(page.title)
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(page.hasCurvedBottom ? .black : .white)
                        .padding(.horizontal, 32)
                        .padding(.top, 105)
                        .transition(.opacity)
                }
                else if page.pageNum == "2" {
                    Text(page.title)
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(page.hasCurvedBottom ? .black : .white)
                        .padding(.horizontal, 32)
                        .padding(.top, 110)
                        .transition(.opacity)
                }
                else if page.pageNum == "3" {
                    Text(page.title)
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(page.hasCurvedBottom ? .black : .white)
                        .padding(.horizontal, 32)
                        .fixedSize()
                        .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .bottom)))
                }
                else if page.pageNum == "4" {
                    Text(page.title)
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(page.hasCurvedBottom ? .black : .white)
                        .padding(.horizontal, 32)
                        .padding(.top, 50)
                        .transition(.move(edge: .top))
                }
                else if page.pageNum == "5" {
                    Text(page.title)
                        .font(.system(size: 20, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.top, 70)
                        .transition(.move(edge: .bottom))
                }
                Spacer()
                Spacer()
            }
        }
    }
}

#Preview {
    IntroView()
}
