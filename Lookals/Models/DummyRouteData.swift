import SwiftUI
import MapKit

// struct untuk menyimpan data Pop-up Fact
struct LookalsFact {
    let imageName: String
    let highlight: String      // Paragraf pertama (fakta utama)
    let details: String        // Paragraf kedua (informasi tambahan)
}

// Single Stop / 1 Destination
struct Destination: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D
    let fact: LookalsFact?
}

// Whole Route / Mission Map (Tetap sama)
struct Route: Identifiable {
    let id = UUID()
    let routeName: String
    let stops: [Destination]
}

let dummyBSDRoute = Route(
    routeName: "BSD City Exploration",
    stops: [
        Destination(
            name: "Prima Flora & Kicau Prima",
            address: "Jalan Letnan Sutopo No. 10, South Tangerang, Banten 15321, Indonesia",
            coordinate: CLLocationCoordinate2D(latitude: -6.29807, longitude: 106.68230),
            fact: nil
        ),
        Destination(
            name: "Pasar Modern BSD City",
            address: "Jalan Letnan Sutopo No. 68, South Tangerang, Banten 15310, Indonesia",
            coordinate: CLLocationCoordinate2D(latitude: -6.30449, longitude: 106.68492),
            fact: LookalsFact(
                imageName: "PasmodFunFact",
                highlight: "Pasar Modern BSD is a historic prototype, making it the first modern traditional market in Indonesia.",
                details: "Built as a national pilot project, it successfully combined the hygiene of a modern mall with the traditional bargaining culture."
            )
        ),
        Destination(
            name: "Rosso' Micro Roastery",
            address: "Jalan Letnan Sutopo No. 26, South Tangerang",
            coordinate: CLLocationCoordinate2D(latitude: -6.30455, longitude: 106.68429),
            fact: LookalsFact(
                imageName: "RossoFunFact", // Sesuai foto di screenshot
                highlight: "Rosso' Micro Roastery was built in 2014, making it one of the oldest coffee shops in BSD.",
                details: "Beyond its legacy as a coffee shop, Rosso Micro Roastery functions as a dedicated education hub, frequently hosting open cupping sessions and workshops."
            )
        ),
        Destination(
            name: "Mare Eatery",
            address: "Jl. Cemara Raya Blok C1",
            coordinate: CLLocationCoordinate2D(latitude: -6.30472, longitude: 106.68375),
            fact: nil
        ),
        Destination(
            name: "The Goats Dept BSD City",
            address: "Jl. Cemara No. 5",
            coordinate: CLLocationCoordinate2D(latitude: -6.30537, longitude: 106.68180),
            fact: nil
        ),
        Destination(
            name: "Taman Perdamaian",
            address: "Jalan Taman Perdamaian Blok A1 No.11, Rawa Buntu, Serpong, South Tangerang",
            coordinate: CLLocationCoordinate2D(latitude: -6.30759, longitude: 106.67919),
            fact: nil
        ),
        Destination(
            name: "Tailor Tukang Jahit BSD",
            address: "Jl Palm Anggur No. 1, South Tangerang",
            coordinate: CLLocationCoordinate2D(latitude: -6.30639, longitude: 106.67922),
            fact: LookalsFact(
                imageName: "JahitFunFact",
                highlight: "Trailor Tukan Jahit is hidden alleyway packed with a bustling community of local tailors.",
                details: "It is the ultimate go-to spot for generations of locals for everything from quick alterations to custom-tailored traditional outfits!"
            )
        ),
        Destination(
            name: "Kelontong Poet-Tea",
            address: "Jalan Palm Sulur I No. BK/31, South Tangerang",
            coordinate: CLLocationCoordinate2D(latitude: -6.30467, longitude: 106.67880),
            fact: nil
        )
    ]
)

// fun fact lokasi yang tidak landmark, bisa muncul saat sedang strolling dll
let funFactAround = Route(
    routeName: "",
    stops: [
        Destination(
            name: "Sushi Matsu BSD",
            address: "Ruko Golden Madrid 2, Jl. Letnan Sutopo, BSD City",
            coordinate: CLLocationCoordinate2D(latitude: -6.30239, longitude: 106.68051),
            fact: LookalsFact(
                imageName: "SushiMatsuFunFact",
                highlight: "Having opened over a decade ago, Sushi Matsu is recognized as one of the oldest and legendary sushi place in BSD City.",
                details: "Their signature, super-creamy 'Volcanoes' roll is a legendary menu item among local foodies."
            )
        ),
    ]
)
