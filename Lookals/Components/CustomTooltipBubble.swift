//
//  CustomTooltipBubble.swift
//  Lookals
//
//  Created by Gisella Jayata on 09/07/26.
//

import SwiftUI

struct CustomTooltipBubble: View {
    let title: String
    let points: Int
    let badge: String?
    let subtitle: String?
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            if let badge {
                Text(badge)
                    .font(.caption.bold())
                    .foregroundColor(.orange)
            }

            Text(title)
                .font(.system(size: 18, weight: .heavy))
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Circle().fill(Color.orange))
                    Text("\(points)")
                        .font(.subheadline.bold())
                }
            }

            Button(action: action) {
                Text(buttonTitle)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.orange))
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(
            TooltipShape()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
        )
        .drawingGroup()
    }
}

struct TooltipShape: Shape {
    var cornerRadius: CGFloat = 28
    var tailWidth: CGFloat = 20
    var tailHeight: CGFloat = 12

    func path(in rect: CGRect) -> Path {
        let bodyRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height - tailHeight)
        var path = Path(roundedRect: bodyRect, cornerRadius: cornerRadius)

        let tailStartX = rect.midX - tailWidth / 2
        let tailEndX = rect.midX + tailWidth / 2

        path.move(to: CGPoint(x: tailStartX, y: bodyRect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: tailEndX, y: bodyRect.maxY))
        path.closeSubpath()

        return path
    }
}

#Preview {
    CustomTooltipBubble(title: "Hype Radar Map", points: 100, badge: nil, subtitle: nil, buttonTitle: "View") {}
        .frame(width: 180)
}
