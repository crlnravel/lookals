import MapKit
import XCTest
@testable import Lookals

@MainActor
final class BSDTourNavigationPolylineTests: XCTestCase {
    func testFallbackPolylineConnectsCurrentUserToActiveDestination() {
        let viewModel = BSDTourViewModel(persistenceStore: TestBSDTourPersistenceStore())

        guard let polyline = viewModel.navigationPolyline else {
            return XCTFail("Expected a fallback navigation polyline while the route is unavailable")
        }

        XCTAssertEqual(polyline.pointCount, 2)
        XCTAssertEqual(polyline.coordinates[0].latitude, BSDTourConfiguration.participants[0].coordinate.latitude, accuracy: 0.000001)
        XCTAssertEqual(polyline.coordinates[0].longitude, BSDTourConfiguration.participants[0].coordinate.longitude, accuracy: 0.000001)
        XCTAssertEqual(polyline.coordinates[1].latitude, BSDTourConfiguration.checkpoints[0].coordinate.latitude, accuracy: 0.000001)
        XCTAssertEqual(polyline.coordinates[1].longitude, BSDTourConfiguration.checkpoints[0].coordinate.longitude, accuracy: 0.000001)

        let mapRect = polyline.boundingMapRect
        let mapRectCenter = MKMapPoint(x: mapRect.midX, y: mapRect.midY).coordinate
        XCTAssertEqual(viewModel.mapRegion.center.latitude, mapRectCenter.latitude, accuracy: 0.000001)
        XCTAssertEqual(viewModel.mapRegion.center.longitude, mapRectCenter.longitude, accuracy: 0.000001)
    }

    func testWalkingRoutePolylineIsPreferredOverFallback() {
        let routeCoordinates = [
            CLLocationCoordinate2D(latitude: -6.30000, longitude: 106.68000),
            CLLocationCoordinate2D(latitude: -6.30100, longitude: 106.68100),
            CLLocationCoordinate2D(latitude: -6.30200, longitude: 106.68200)
        ]
        let routePolyline = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)

        let result = BSDTourViewModel.navigationPolyline(
            routePolyline: routePolyline,
            source: CLLocationCoordinate2D(latitude: -6.30490, longitude: 106.67835),
            destination: CLLocationCoordinate2D(latitude: -6.29807, longitude: 106.68230)
        )

        XCTAssertTrue(result === routePolyline)
    }

    func testNavigationPolylineIsUnavailableAfterArrivalAndDuringQuest() {
        let viewModel = BSDTourViewModel(persistenceStore: TestBSDTourPersistenceStore())

        viewModel.simulateArrival()

        XCTAssertEqual(viewModel.phase, .waitingToShake)
        XCTAssertNil(viewModel.navigationPolyline)

        viewModel.joinAllParticipants()

        XCTAssertEqual(viewModel.phase, .quest)
        XCTAssertNil(viewModel.navigationPolyline)
    }
}

private extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var values = Array(repeating: CLLocationCoordinate2D(), count: pointCount)
        getCoordinates(&values, range: NSRange(location: 0, length: pointCount))
        return values
    }
}

private struct TestBSDTourPersistenceStore: BSDTourPersistenceStore {
    func loadSnapshot(tourID: String) async throws -> BSDTourSnapshot? { nil }
    func saveSnapshot(_ snapshot: BSDTourSnapshot) async throws {}
    func reset(tourID: String) async throws {}
}
