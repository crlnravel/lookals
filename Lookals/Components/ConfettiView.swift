//
//  ConfettiView.swift
//  Lookals
//
//  Created by Gisella Jayata on 09/07/26.
//

import SwiftUI

struct ConfettiView: View {
    @State private var animateY: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let screenHeight = geo.size.height
            
            ZStack {
                Image("Confetti")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: screenHeight)
                    .offset(y: animateY)
                
                Image("Confetti")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: screenHeight)
                    .offset(y: animateY - screenHeight)
            }
            .onAppear {
                withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                    animateY = screenHeight
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

#Preview {
    ZStack {
        ConfettiView()
    }
}
