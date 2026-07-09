//
//  CouponCard.swift
//  Lookals
//
//  Created by Kevin Halim on 08/07/26.
//
import SwiftUI

struct CouponCard: View {
    let coupon: Coupon
    let isOwned: Bool
    let onRedeem: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Color.orange)
                .frame(width: 12)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(coupon.title)
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text(coupon.description)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 0)
                
                HStack(spacing: 12) {
                    if isOwned {
                        Text("Owned")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    } else {
                        Button(action: onRedeem) {
                            Text("Redeem")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.orange))
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Circle().fill(Color.orange))
                            
                            Text("\(coupon.pointsRequired)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack {
                Color.gray.opacity(0.2)
                Image(coupon.imageName)
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }
            .frame(width: 110)
            .clipped()
        }
        .frame(height: 120)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}
