//
//  MapMemoryComponent.swift
//  Lookals
//

import SwiftUI

struct MapPhotoPinView: View {
    var position: CGPoint
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image("tourMap3")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(6)
                    .padding(.bottom, 10)
                    .background(
                        PhotoPinShape()
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.15), radius: 6, y: 4)
                    )

                Text("2")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color(red: 0.54, green: 0.81, blue: 0.98)))
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .offset(x: 8, y: -8)
            }
        }
        .buttonStyle(.plain)
        .position(position)
    }
}

// MARK: - Custom Shape for the Pin Tail
struct PhotoPinShape: Shape {
    var cornerRadius: CGFloat = 14
    var tailWidth: CGFloat = 16
    var tailHeight: CGFloat = 10

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
