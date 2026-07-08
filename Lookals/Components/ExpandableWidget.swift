//
//  ExpandableWidget.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import SwiftUI

struct ExpandableWidget<CollapsedContent: View, ExpandedContent: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Binding private var isExpanded: Bool
    @Namespace private var cardNamespace

    private let collapsedMaxWidth: CGFloat
    private let expandedMaxWidth: CGFloat
    private let horizontalPadding: CGFloat
    private let edgePadding: CGFloat
    private let collapsedContent: CollapsedContent
    private let expandedContent: ExpandedContent

    init(
        isExpanded: Binding<Bool>,
        collapsedMaxWidth: CGFloat = 392,
        expandedMaxWidth: CGFloat = 360,
        horizontalPadding: CGFloat = 20,
        edgePadding: CGFloat = 16,
        @ViewBuilder collapsedContent: () -> CollapsedContent,
        @ViewBuilder expandedContent: () -> ExpandedContent
    ) {
        self._isExpanded = isExpanded
        self.collapsedMaxWidth = collapsedMaxWidth
        self.expandedMaxWidth = expandedMaxWidth
        self.horizontalPadding = horizontalPadding
        self.edgePadding = edgePadding
        self.collapsedContent = collapsedContent()
        self.expandedContent = expandedContent()
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: isExpanded ? .center : .bottom) {
                if isExpanded {
                    dismissLayer
                }

                card
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, topPadding(for: proxy))
                    .padding(.bottom, bottomPadding(for: proxy))
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height,
                alignment: isExpanded ? .center : .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        }
        .animation(animation, value: isExpanded)
    }

    private var card: some View {
        VStack(spacing: 0) {
            if isExpanded {
                expandedContent
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.96, anchor: .bottom).combined(with: .opacity),
                            removal: .scale(scale: 0.98, anchor: .bottom).combined(with: .opacity)
                        )
                    )
            } else {
                collapsedContent
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.98, anchor: .bottom).combined(with: .opacity),
                            removal: .scale(scale: 0.96, anchor: .bottom).combined(with: .opacity)
                        )
                    )
            }
        }
        .frame(maxWidth: isExpanded ? expandedMaxWidth : collapsedMaxWidth)
        .background {
            RoundedRectangle(cornerRadius: isExpanded ? 32 : 28, style: .continuous)
                .fill(Color(.systemBackground))
                .matchedGeometryEffect(id: "quest-card-background", in: cardNamespace)
        }
        .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 32 : 28, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 20, x: 0, y: 10)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: isExpanded ? 32 : 28, style: .continuous))
        .overlay(alignment: .topLeading) {
            expansionControl
                .padding(.top, 24)
                .padding(.leading, 24)
        }
        .accessibilityAction(.escape, collapse)
    }

    private var expansionControl: some View {
        Button(action: toggleExpansion) {
            Image(systemName: expansionControlSystemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
                .background(.thinMaterial, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect()
        .zIndex(1)
        .accessibilityLabel(isExpanded ? "Collapse quest" : "Expand quest")
    }

    private var expansionControlSystemName: String {
        isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
    }

    private var dismissLayer: some View {
        Color.black.opacity(0.28)
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture(perform: collapse)
            .accessibilityHidden(true)
    }

    private var animation: Animation? {
        reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.86, blendDuration: 0.12)
    }

    private func topPadding(for proxy: GeometryProxy) -> CGFloat {
        isExpanded ? centeredVerticalPadding(for: proxy) : 0
    }

    private func bottomPadding(for proxy: GeometryProxy) -> CGFloat {
        isExpanded ? centeredVerticalPadding(for: proxy) : proxy.safeAreaInsets.bottom + edgePadding
    }

    private func centeredVerticalPadding(for proxy: GeometryProxy) -> CGFloat {
        max(proxy.safeAreaInsets.top, proxy.safeAreaInsets.bottom) + edgePadding
    }

    private func toggleExpansion() {
        setExpanded(!isExpanded)
    }

    private func collapse() {
        setExpanded(false)
    }

    private func setExpanded(_ expanded: Bool) {
        if reduceMotion {
            isExpanded = expanded
        } else {
            withAnimation(animation) {
                isExpanded = expanded
            }
        }
    }
}

#Preview("Expandable Widget") {
    struct PreviewHost: View {
        @State private var isExpanded = true

        var body: some View {
            ZStack {
                PreviewBackdropContent()

                ExpandableWidget(isExpanded: $isExpanded) {
                    QuestCollapsedContent(
                        questNumber: 1,
                        title: "Quiz",
                        reward: 30
                    )
                } expandedContent: {
                    QuizQuestContent(
                        questNumber: 1,
                        title: "Quiz",
                        question: "What's the name of Kelontong Poet-Tea owner?",
                        options: ["Julian Yang", "Kevin Halim", "Carleano Ravel", "Gisella Jayanta"],
                        selectedOption: .constant(nil),
                        reward: 30,
                        onSubmit: {}
                    )
                }
            }
        }
    }

    struct PreviewBackdropContent: View {
        var body: some View {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemMint), Color(.systemBlue), Color(.systemOrange)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("Map Content Behind Widget")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(.white)

                    ForEach(0..<4, id: \.self) { index in
                        HStack(spacing: 16) {
                            Image(systemName: index.isMultiple(of: 2) ? "mappin.circle.fill" : "person.crop.circle.fill")
                                .font(.largeTitle)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(index.isMultiple(of: 2) ? "Quest Stop" : "Nearby Friend")
                                    .font(.headline.weight(.bold))

                                Text("This background should darken when expanded.")
                                    .font(.subheadline)
                            }

                            Spacer()
                        }
                        .foregroundStyle(.white)
                        .padding(16)
                        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.horizontal, 32)
            }
        }
    }

    return PreviewHost()
}
