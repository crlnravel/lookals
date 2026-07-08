//
//  LoginBackgroundView.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 08/07/26.
//

import SwiftUI

struct LoginBackgroundView: View {
    let imageNames: [String]
    let selectedImageIndex: Int
    let reduceMotion: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(imageNames.indices, id: \.self) { index in
                    Image(imageNames[index])
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .opacity(index == selectedImageIndex ? 1 : 0)
                        .accessibilityHidden(true)
                }

                LinearGradient(
                    colors: [
                        .black.opacity(0.08),
                        .black.opacity(0.12),
                        .black.opacity(0.4)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.8), value: selectedImageIndex)
            .clipped()
        }
    }
}

#Preview {
    LoginBackgroundView(
        imageNames: ["Login Image 1", "Login Image 2"],
        selectedImageIndex: 0,
        reduceMotion: false
    )
}
