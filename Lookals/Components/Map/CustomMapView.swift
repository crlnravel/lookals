//
//  CustomMapView.swift
//  Lookals
//
//  Created by Carleano Ravelza Wongso on 09/07/26.
//

import MapKit
import SwiftUI

struct CustomMapMarker: Identifiable {
    let id: String
    let style: RadarMarkerStyle
    let xRatio: CGFloat
    let yRatio: CGFloat
}

struct CustomCoordinateMapMarker: Identifiable {
    let id: String
    let style: RadarMarkerStyle
    let coordinate: CLLocationCoordinate2D
}

struct CustomMapHeaderAction {
    let systemImage: String
    let accessibilityLabel: String
    let background: Color
    let foreground: Color
    let action: () -> Void
}

struct CustomMapView<Overlay: View, BottomOverlay: View>: View {
    let title: String
    let onBack: () -> Void
    let onLocate: () -> Void
    let markers: [CustomMapMarker]
    let coordinateMarkers: [CustomCoordinateMapMarker]
    let navigationPolyline: MKPolyline?
    let showsUserLocation: Bool
    let cameraRegion: MKCoordinateRegion
    let trailingAction: CustomMapHeaderAction?
    let overlay: () -> Overlay
    let bottomOverlay: () -> BottomOverlay

    @State private var cameraPosition: MapCameraPosition

    init(
        title: String,
        region: MKCoordinateRegion,
        markers: [CustomMapMarker] = [],
        coordinateMarkers: [CustomCoordinateMapMarker] = [],
        navigationPolyline: MKPolyline? = nil,
        showsUserLocation: Bool = false,
        onBack: @escaping () -> Void = {},
        onLocate: @escaping () -> Void = {},
        trailingAction: CustomMapHeaderAction? = nil,
        @ViewBuilder overlay: @escaping () -> Overlay = { EmptyView() },
        @ViewBuilder bottomOverlay: @escaping () -> BottomOverlay
    ) {
        self.title = title
        self.onBack = onBack
        self.onLocate = onLocate
        self.markers = markers
        self.coordinateMarkers = coordinateMarkers
        self.navigationPolyline = navigationPolyline
        self.showsUserLocation = showsUserLocation
        self.cameraRegion = region
        self.trailingAction = trailingAction
        self.overlay = overlay
        self.bottomOverlay = bottomOverlay
        self._cameraPosition = State(initialValue: .region(region))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                mapBackground

                overlay()

                mapMarkers(in: proxy.size)

                mapHeader(topInset: proxy.safeAreaInsets.top)

                bottomOverlay()
            }
            .padding(.bottom, 10)
            .ignoresSafeArea()
            .onChange(of: cameraRegionKey) {
                withAnimation(.smooth(duration: 0.35)) {
                    cameraPosition = .region(cameraRegion)
                }
            }
        }
    }

    private func mapHeader(topInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack {
                mapHeaderButton(
                    systemImage: "chevron.left",
                    accessibilityLabel: "Go back",
                    background: Color(.systemBackground),
                    foreground: .primary,
                    action: onBack
                )

                Spacer()

                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                if let trailingAction {
                    mapHeaderButton(
                        systemImage: trailingAction.systemImage,
                        accessibilityLabel: trailingAction.accessibilityLabel,
                        background: trailingAction.background,
                        foreground: trailingAction.foreground,
                        action: trailingAction.action
                    )
                } else {
                    mapHeaderButton(
                        systemImage: "location",
                        accessibilityLabel: "Show current location",
                        background: Color.accentColor,
                        foreground: .white,
                        action: locateUser
                    )
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, topInset + 16)

            Spacer()
        }
    }

    private func mapHeaderButton(
        systemImage: String,
        accessibilityLabel: String,
        background: Color,
        foreground: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(foreground)
                .frame(width: 44, height: 44)
                .background(background, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect()
        .accessibilityLabel(accessibilityLabel)
    }

    private func locateUser() {
        onLocate()

        guard showsUserLocation else { return }

        withAnimation(.smooth(duration: 0.35)) {
            cameraPosition = .userLocation(
                followsHeading: false,
                fallback: .region(cameraRegion)
            )
        }
    }

    private var mapBackground: some View {
        Map(position: $cameraPosition, interactionModes: .all) {
            if let navigationPolyline {
                MapPolyline(navigationPolyline)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }

            ForEach(coordinateMarkers) { marker in
                Annotation(marker.style.accessibilityLabel, coordinate: marker.coordinate) {
                    RadarMarker(style: marker.style)
                }
            }

            if showsUserLocation {
                UserAnnotation()
            }
        }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted))
            .saturation(0.72)
            .opacity(0.82)
            .overlay {
                Color.white
                    .opacity(0.16)
                    .allowsHitTesting(false)
            }
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func mapMarkers(in size: CGSize) -> some View {
        ForEach(markers) { marker in
            RadarMarker(style: marker.style)
                .position(x: size.width * marker.xRatio, y: size.height * marker.yRatio)
        }
        .allowsHitTesting(false)
    }

    private var cameraRegionKey: String {
        [
            cameraRegion.center.latitude,
            cameraRegion.center.longitude,
            cameraRegion.span.latitudeDelta,
            cameraRegion.span.longitudeDelta
        ]
        .map { String(format: "%.6f", $0) }
        .joined(separator: ":")
    }
}
