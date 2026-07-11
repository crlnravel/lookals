//
//  MemoryPhotoTitleView.swift
//  Lookals
//
//  Created by Codex on 08/07/26.
//

import SwiftUI

struct MemoryPhotoTitleView: View {
    let photo: MemoryPhoto?

    var body: some View {
        VStack(spacing: 2) {
            Text(photo?.title ?? "Memory")
                .font(.subheadline.bold())

            if let time = photo?.time {
                Text(time)
                    .font(.subheadline.bold())
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
    }
}
