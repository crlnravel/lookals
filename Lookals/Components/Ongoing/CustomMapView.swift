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

struct CustomMapView<Overlay: View, BottomOverlay: View>: View {
    let title: String
    let onBack: () -> Void
    let onLocate: () -> Void
    let markers: [CustomMapMarker]
    let overlay: () -> Overlay
    let bottomOverlay: () -> BottomOverlay

    @State private var cameraPosition: MapCameraPosition

    init(
        title: String,
        region: MKCoordinateRegion,
        markers: [CustomMapMarker] = [],
        onBack: @escaping () -> Void = {},
        onLocate: @escaping () -> Void = {},
        @ViewBuilder overlay: @escaping () -> Overlay = { EmptyView() },
        @ViewBuilder bottomOverlay: @escaping () -> BottomOverlay
    ) {
        self.title = title
        self.onBack = onBack
        self.onLocate = onLocate
        self.markers = markers
        self.overlay = overlay
        self.bottomOverlay = bottomOverlay
        self._cameraPosition = State(initialValue: .region(region))
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    mapBackground

                    overlay()

                    mapMarkers(in: proxy.size)

                    bottomOverlay()
                }
                .padding(.bottom, 10)
                .ignoresSafeArea()
            }
            .navigationTitle(title)
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarIconButton(
                    placement: .topBarLeading,
                    systemImage: "chevron.left",
                    accessibilityLabel: "Go back",
                    background: .white,
                    action: onBack
                )

                ToolbarIconButton(
                    placement: .topBarTrailing,
                    systemImage: "location.north.fill",
                    accessibilityLabel: "Show current location",
                    background: .accent,
                    foreground: .white,
                    action: onLocate
                )
            }
        }
    }

    private var mapBackground: some View {
        Map(position: $cameraPosition, interactionModes: .pan)
            .mapStyle(.standard(elevation: .flat, emphasis: .muted))
            .saturation(0.72)
            .opacity(0.82)
            .overlay(Color.white.opacity(0.16))
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
}
