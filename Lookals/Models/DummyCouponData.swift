//
//  DummyCouponData.swift
//  Lookals
//
//  Created by Kevin Halim on 08/07/26.
//
import Foundation

struct Coupon: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let description: String
    let pointsRequired: Int
    let imageName: String
}

let dummyCoupons = [
    Coupon(title: "10% off", description: "Luc Coffee, Jl. BSD Raya Barat, Kabupaten Tangerang", pointsRequired: 50, imageName: "Coupon1"),
    Coupon(title: "Free 1 Milk Tea", description: "Kelontong Poet-Tea, Jl. BSD Raya Barat, Kabupaten Tangerang", pointsRequired: 150, imageName: "Coupon2")
]
