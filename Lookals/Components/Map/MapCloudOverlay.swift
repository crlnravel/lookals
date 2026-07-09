//
//  MapCloudOverlay.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import SwiftUI

struct MapCloudOverlay: View {
    private let clouds = [
        MapCloudPlacement(x: 0.18, y: 0.12, width: 260, opacity: 1, rotation: -8),
        MapCloudPlacement(x: 0.68, y: 0.13, width: 320, opacity: 1, rotation: 7),
        MapCloudPlacement(x: 0.86, y: 0.34, width: 280, opacity: 1, rotation: -12),
        MapCloudPlacement(x: 0.22, y: 0.80, width: 300, opacity: 1, rotation: 10),
        MapCloudPlacement(x: 0.70, y: 0.86, width: 340, opacity: 1, rotation: -5),
        MapCloudPlacement(x: 0.47, y: 0.43, width: 360, opacity: 1, rotation: 4)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.white.opacity(0.16)

                ForEach(clouds) { cloud in
                    Image("Cloud")
                        .resizable()
                        .scaledToFit()
                        .frame(width: cloud.width)
                        .opacity(cloud.opacity)
                        .rotationEffect(.degrees(cloud.rotation))
                        .position(
                            x: proxy.size.width * cloud.x,
                            y: proxy.size.height * cloud.y
                        )
                        .blendMode(.screen)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct MapCloudPlacement: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let opacity: Double
    let rotation: Double
}

#Preview("Map Cloud Overlay") {
    ZStack {
        Color(.systemBlue)
            .opacity(0.35)
            .ignoresSafeArea()

        MapCloudOverlay()
            .ignoresSafeArea()
    }
}
