//
//  TourMap.swift
//  Lookals
//
//  Created by Gisella Jayata on 09/07/26.
//

import Foundation

struct TourMap: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var area: String
    var title: String
    var subtitleTags: [String]
    var summary: String
    var imageName: String
    var image: String
    var pointCost: Int
    var quests: Int
    var landmarks: Int
    var duration: String
    var priceText: String
    var capacity: Int
    var meetingPoint: String
    var fixedTime: String
    var isAvailable: Bool
}

extension TourMap {
    static let sampleData: [TourMap] = [
        TourMap(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            area: "South Tangerang",
            title: "The Blueprint",
            subtitleTags: ["Plants", "Coffee", "Pasta", "Entertainment", "History", "Tea"],
            summary: "See exactly where BSD actually lives, not the malls, the people running it. Eight stops, real locals, one map. Show up and leave your mark.",
            imageName: "Map1",
            image: "tourMap1",
            pointCost: 250,
            quests: 10,
            landmarks: 8,
            duration: "2 - 4 Hours",
            priceText: "~IDR120K",
            capacity: 5,
            meetingPoint: "Bumi Serpong Damai, Jl. Letnan Sutopo Jalan Kompleks Bsd Sektor 14 No.2, RW.3, Lengkong Gudang Tim., Kec. Serpong, Kota Tangerang Selatan, Banten 15330, Indonesia",
            fixedTime: "14.00",
            isAvailable: true
        ),
        TourMap(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            area: "South Tangerang",
            title: "The Modern Trail",
            subtitleTags: ["Urban", "Coffee", "History", "Pastry", "Park"],
            summary: "See exactly where the internet is obsessing over in real time. Here’s the most viral spots so you can just show up and catch the vibe.",
            imageName: "Map2",
            image: "tourMap2",
            pointCost: 220,
            quests: 9,
            landmarks: 6,
            duration: "2 - 3 Hours",
            priceText: "~IDR150K",
            capacity: 5,
            meetingPoint: "TBA",
            fixedTime: "TBA",
            isAvailable: false
        ),
        TourMap(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            area: "South Tangerang",
            title: "The Locals’ Choice",
            subtitleTags: ["Culture", "Local Foods", "Spice", "Wellness", "Community"],
            summary: "Forget the tourist traps, the locals are the one who run the city. These are the hidden nodes and daily staples keeping the neighborhood alive.",
            imageName: "Map3",
            image: "tourMap3",
            pointCost: 220,
            quests: 10,
            landmarks: 7,
            duration: "2 - 3 Hours",
            priceText: "~IDR100K",
            capacity: 5,
            meetingPoint: "TBA",
            fixedTime: "TBA",
            isAvailable: false
        )
    ]
}
