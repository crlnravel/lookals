//
//  MapCloudOverlay.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import SwiftUI

struct MapCloudOverlay: View {
    let stage: Int

    init(stage: Int = 0) {
        self.stage = stage
    }

    private var clouds: [MapCloudPlacement] {
        MapCloudPlacement.configurations[
            min(max(stage, 0), MapCloudPlacement.configurations.count - 1)
        ]
    }

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

    static let configurations: [[MapCloudPlacement]] = [
        [
            MapCloudPlacement(x: 0.18, y: 0.12, width: 260, opacity: 1, rotation: -8),
            MapCloudPlacement(x: 0.68, y: 0.13, width: 320, opacity: 1, rotation: 7),
            MapCloudPlacement(x: 0.86, y: 0.34, width: 280, opacity: 1, rotation: -12),
            MapCloudPlacement(x: 0.22, y: 0.80, width: 300, opacity: 1, rotation: 10),
            MapCloudPlacement(x: 0.70, y: 0.86, width: 340, opacity: 1, rotation: -5),
            MapCloudPlacement(x: 0.47, y: 0.43, width: 360, opacity: 1, rotation: 4)
        ],
        [
            MapCloudPlacement(x: 0.72, y: 0.12, width: 320, opacity: 1, rotation: 7),
            MapCloudPlacement(x: 0.88, y: 0.34, width: 280, opacity: 1, rotation: -12),
            MapCloudPlacement(x: 0.22, y: 0.80, width: 300, opacity: 1, rotation: 10),
            MapCloudPlacement(x: 0.70, y: 0.86, width: 340, opacity: 1, rotation: -5),
            MapCloudPlacement(x: 0.52, y: 0.43, width: 340, opacity: 0.94, rotation: 4)
        ],
        [
            MapCloudPlacement(x: 0.82, y: 0.18, width: 300, opacity: 1, rotation: 7),
            MapCloudPlacement(x: 0.88, y: 0.46, width: 280, opacity: 1, rotation: -12),
            MapCloudPlacement(x: 0.22, y: 0.80, width: 300, opacity: 1, rotation: 10),
            MapCloudPlacement(x: 0.70, y: 0.86, width: 320, opacity: 1, rotation: -5)
        ],
        [
            MapCloudPlacement(x: 0.18, y: 0.12, width: 220, opacity: 0.9, rotation: -8),
            MapCloudPlacement(x: 0.88, y: 0.46, width: 260, opacity: 1, rotation: -12),
            MapCloudPlacement(x: 0.22, y: 0.82, width: 280, opacity: 1, rotation: 10),
            MapCloudPlacement(x: 0.72, y: 0.86, width: 320, opacity: 1, rotation: -5)
        ],
        [
            MapCloudPlacement(x: 0.14, y: 0.16, width: 220, opacity: 0.86, rotation: -8),
            MapCloudPlacement(x: 0.88, y: 0.48, width: 260, opacity: 0.96, rotation: -12),
            MapCloudPlacement(x: 0.22, y: 0.84, width: 280, opacity: 1, rotation: 10)
        ],
        [
            MapCloudPlacement(x: 0.14, y: 0.16, width: 220, opacity: 0.82, rotation: -8),
            MapCloudPlacement(x: 0.88, y: 0.48, width: 240, opacity: 0.9, rotation: -12)
        ],
        [
            MapCloudPlacement(x: 0.16, y: 0.16, width: 220, opacity: 0.78, rotation: -8)
        ],
        []
    ]
}

#Preview("Map Cloud Overlay") {
    ZStack {
        Color(.systemBlue)
            .opacity(0.35)
            .ignoresSafeArea()

        MapCloudOverlay(stage: 0)
            .ignoresSafeArea()
    }
}
