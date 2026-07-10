//
//  TourMap.swift
//  Lookals
//
//  Created by Gisella Jayata on 09/07/26.
//

import Foundation

struct TourMap: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var subtitleTags: [String]
    var summary: String
    var imageName: String
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
            title: "Hype Radar Map",
            subtitleTags: ["Coffee", "Food", "Entertainment", "History"],
            summary: "See exactly where the internet is obsessing over in real time. Here's the most viral spots so you can just show up and catch the vibe.",
            imageName: "Map1",
            pointCost: 100,
            quests: 4,
            landmarks: 3,
            duration: "1 - 2 Hours",
            priceText: "~IDR100K",
            capacity: 5,
            meetingPoint: "Kelontong Poet-Tea, Jl. BSD Raya Barat, Sampora, Kec. Cisauk, Kabupaten Tangerang, Banten, Indonesia",
            fixedTime: "14.00",
            isAvailable: true
        ),
        TourMap(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            title: "Locals' Choice",
            subtitleTags: ["Food", "Culture", "Hidden Gems"],
            summary: "The spots locals actually go to, no tourist traps allowed. Curated by the people who live here.",
            imageName: "Map2",
            pointCost: 120,
            quests: 5,
            landmarks: 4,
            duration: "2 - 3 Hours",
            priceText: "~IDR150K",
            capacity: 6,
            meetingPoint: "TBA",
            fixedTime: "TBA",
            isAvailable: false
        ),
        TourMap(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
            title: "Sweet Trail",
            subtitleTags: ["Dessert", "Cafe", "Photo Spots"],
            summary: "A sugar-dusted trail through the best dessert spots in town, made for the sweet tooth explorer.",
            imageName: "Map3",
            pointCost: 120,
            quests: 4,
            landmarks: 3,
            duration: "1 - 2 Hours",
            priceText: "~IDR120K",
            capacity: 5,
            meetingPoint: "TBA",
            fixedTime: "TBA",
            isAvailable: false
        )
    ]
}
