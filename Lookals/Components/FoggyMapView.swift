//
//  FoggyMapView.swift
//  Lookals
//
//  Created by Gisella Jayata on 09/07/26.
//

import SwiftUI

struct FoggyMapView<Content: View>: View {
    let isFogged: Bool
    let fogImageName: String 
    let content: Content

    @State private var animatePhase = false

    init(isFogged: Bool, fogImageName: String, @ViewBuilder content: () -> Content) {
        self.isFogged = isFogged
        self.fogImageName = fogImageName
        self.content = content()
    }

    var body: some View {
            content
                .overlay(
                    Group {
                        if isFogged {
                            fogLayer
                                .allowsHitTesting(false)
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                        }
                    }
                )
                .onAppear {
                    withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                        animatePhase.toggle()
                    }
                }
        }

    private var fogLayer: some View {
        Image(fogImageName)
            .resizable()
            .scaledToFill()
            .scaleEffect(1.5)
            .offset(x: animatePhase ? 14 : -14, y: animatePhase ? -10 : 10)
            .opacity(0.9)
    }
}

#Preview {
    FoggyMapView(isFogged: true, fogImageName: "fogMap1") {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.orange.opacity(0.4))
    }
    .frame(width: 180, height: 240)
}
