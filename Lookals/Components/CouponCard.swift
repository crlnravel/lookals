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
    var canRedeem: Bool = true // Defaults to true so "My Coupons" stay colored
    let action: () -> Void
    
    var body: some View {
        // 1. Dynamic theme color logic
        let themeColor = (isOwned || canRedeem) ? Color.orange : Color.gray.opacity(0.4)
        
        HStack(spacing: 0) {
            // Left Edge Accent Bar
            themeColor
                .frame(width: 12)
            
            // Text and Buttons Content
            VStack(alignment: .leading, spacing: 8) {
                Text(coupon.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text(coupon.description)
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.8))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 0)
                
                HStack {
                    if !isOwned {
                        Button(action: action) {
                            Text("Redeem")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(canRedeem ? .white : .gray)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(canRedeem ? themeColor : Color.gray.opacity(0.2)))
                        }
                        // Disables the button if they don't have enough points!
                        .disabled(!canRedeem)
                    }
                    
                    Spacer()
                    
                    if !isOwned {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10, weight: .bold)) // slightly smaller star
                                .foregroundColor(.white) // Star is always white
                                .padding(5) // Space between the star and the edge of the circle
                                .background(Circle().fill(themeColor)) // The dynamic colored circle
                            
                            Text("\(coupon.pointsRequired)")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(themeColor)
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Image on the Right
            Image(coupon.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 130, height: 130)
                .clipped()
        }
        .frame(height: 130)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
