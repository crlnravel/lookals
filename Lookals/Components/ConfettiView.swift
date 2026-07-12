//
//  ConfettiView.swift
//  Lookals
//
//  Created by Gisella Jayata on 09/07/26.
//

import SwiftUI

struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var isFalling = false
    @State private var startTime = Date()

    private let loopDuration: TimeInterval = 5.0

    var body: some View {
        GeometryReader { geo in
            let screenHeight = geo.size.height

            TimelineView(.animation(paused: !isActive || !isFalling)) { context in
                let elapsed = context.date.timeIntervalSince(startTime)
                let progress = elapsed.truncatingRemainder(dividingBy: loopDuration) / loopDuration
                let offsetY = CGFloat(progress) * screenHeight

                ZStack {
                    Image("Confetti")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: screenHeight)
                        .offset(y: offsetY)

                    Image("Confetti")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: screenHeight)
                        .offset(y: offsetY - screenHeight)
                }
            }
            .onAppear {
                startTime = Date()
                isFalling = true
            }
            .onDisappear {
                isFalling = false
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        ConfettiView(isActive: .constant(true))
    }
}
