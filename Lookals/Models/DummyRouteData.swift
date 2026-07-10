//
//  DummyRouteData.swift
//  Lookals
//
//  Created by Kevin Halim on 10/07/26.
//

import SwiftUI
import MapKit

// Single Stop / 1 Destination
struct RouteStop: Identifiable {
    let id = UUID()
    let name: String
    let address: String
    let coordinate: CLLocationCoordinate2D // For MapKit coordinate later!
}

// Whole Route / Mission Map
struct Route: Identifiable {
    let id = UUID()
    let routeName: String
    let stops: [RouteStop]
}

// 3. Create your Dummy Data based on your screenshot
let dummyBSDRoute = Route(
    routeName: "BSD City Exploration",
    stops: [
        RouteStop(
            name: "Prima Flora & Kicau Prima",
            address: "Jalan Letnan Sutopo No. 10, South Tangerang, Banten 15321, Indonesia",
            coordinate: CLLocationCoordinate2D(latitude: -6.29807, longitude: 106.68230)
        ),
        RouteStop(
            name: "Pasar Modern BSD City",
            address: "Jalan Letnan Sutopo No. 68, South Tangerang, Banten 15310, Indonesia",
            coordinate: CLLocationCoordinate2D(latitude: -6.30449, longitude: 106.68492)
        ),
        RouteStop(
            name: "Rosso' Micro Roastery",
            address: "Jalan Letnan Sutopo No. 26, South Tangerang",
            coordinate: CLLocationCoordinate2D(latitude: -6.30455, longitude: 106.68429)
        ),
        RouteStop(
            name: "Mare Eatery",
            address: "Jl. Cemara Raya Blok C1",
            coordinate: CLLocationCoordinate2D(latitude: -6.30472, longitude: 106.68375)
        ),
        RouteStop(
            name: "The Goats Dept BSD City",
            address: "Jl. Cemara No. 5",
            coordinate: CLLocationCoordinate2D(latitude: -6.30537, longitude: 106.68180)
        ),
        RouteStop(
            name: "Taman Perdamaian",
            address: "Jalan Taman Perdamaian Blok A1 No.11, Rawa Buntu, Serpong, South Tangerang",
            coordinate: CLLocationCoordinate2D(latitude: -6.30759, longitude: 106.67919)
        ),
        RouteStop(
            name: "Tailor Tukang Jahit BSD",
            address: "Jl Palm Anggur No. 1, South Tangerang",
            coordinate: CLLocationCoordinate2D(latitude: -6.30639, longitude: 106.67922)
        ),
        RouteStop(
            name: "Kelontong Poet-Tea",
            address: "Jalan Palm Sulur I No. BK/31, South Tangerang",
            coordinate: CLLocationCoordinate2D(latitude: -6.30489, longitude: 106.67881)
        )
    ]
)

//struct RouteMapView: View {
//    let route: Route
//    
//    // State to hold the calculated route segments from Apple
//    @State private var walkingRoutes: [MKRoute] = []
//    
//    var body: some View {
//        Map {
//            // 1. Draw the real-world walking routes once they are loaded
//            ForEach(walkingRoutes, id: \.self) { routeSegment in
//                MapPolyline(routeSegment.polyline)
//                    .stroke(.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
//            }
//            
//            // 2. Loop through the stops to create custom numbered map pins
//            ForEach(Array(route.stops.enumerated()), id: \.element.id) { index, stop in
//                Annotation(stop.name, coordinate: stop.coordinate) {
//                    ZStack {
//                        Circle()
//                            .fill(Color.orange)
//                            .frame(width: 30, height: 30)
//                            .shadow(radius: 3)
//                        
//                        Text("\(index + 1)")
//                            .font(.caption)
//                            .fontWeight(.bold)
//                            .foregroundColor(.white)
//                    }
//                }
//            }
//        }
//        .navigationTitle(route.routeName)
//        .navigationBarTitleDisplayMode(.inline)
//        .mapControls {
//            MapCompass()
//            MapPitchToggle()
//            MapUserLocationButton()
//        }
//        // 3. Trigger the calculation as soon as the map appears
//        .task {
//            await calculateWalkingRoutes()
//        }
//    }
//    
//    // MARK: - Route Calculation Logic
//    private func calculateWalkingRoutes() async {
//        // We need at least 2 stops to calculate a route
//        guard route.stops.count > 1 else { return }
//        
//        var calculatedSegments: [MKRoute] = []
//        
//        // Loop through the stops in pairs (0->1, 1->2, 2->3...)
//        for i in 0..<(route.stops.count - 1) {
//            let start = route.stops[i]
//            let end = route.stops[i + 1]
//            
//            let request = MKDirections.Request()
//            request.source = MKMapItem(placemark: MKPlacemark(coordinate: start.coordinate))
//            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end.coordinate))
//            
//            // Set the transport type to walking!
//            request.transportType = .walking
//            
//            let directions = MKDirections(request: request)
//            
//            do {
//                let response = try await directions.calculate()
//                if let route = response.routes.first {
//                    calculatedSegments.append(route)
//                }
//            } catch {
//                print("Failed to calculate route from \(start.name) to \(end.name): \(error.localizedDescription)")
//            }
//        }
//        
//        // Update the UI with all the combined routes
//        await MainActor.run {
//            self.walkingRoutes = calculatedSegments
//        }
//    }
//}
//
//#Preview {
//    NavigationStack {
//        RouteMapView(route: dummyBSDRoute)
//    }
//}
