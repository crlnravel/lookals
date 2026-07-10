//  HomepageView.swift
//  Lookals
//
//

import SwiftUI

// MARK: - Navigation Routes

enum HomeRoute: Hashable {
    case profile
    case ongoingItinerary
    case checkAvailability(TourMap)
}

struct HomepageView: View {
    @StateObject private var appState = HomeStateManager()
    @State private var selectedMapForTooltip: TourMap? = nil
    @State private var detailMap: TourMap? = nil
    @State private var showTourDetails = false
    @State private var path: [HomeRoute] = []

    private struct MapLayout {
        let xFraction: CGFloat
        let yFraction: CGFloat
        let widthFraction: CGFloat
        let heightFraction: CGFloat
    }

    private let mapLayouts: [MapLayout] = [
        MapLayout(xFraction: 0.30, yFraction: 0.44, widthFraction: 0.44, heightFraction: 0.33), // Hype Radar Map
        MapLayout(xFraction: 0.74, yFraction: 0.31, widthFraction: 0.36, heightFraction: 0.34), // Locals' Choice
        MapLayout(xFraction: 0.66, yFraction: 0.55, widthFraction: 0.43, heightFraction: 0.34)  // Sweet Trail
    ]

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                backgroundMap
                    .overlay{
                        Image("Fog")
                    }

                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedMapForTooltip = nil
                        }
                    }

                mapCardsLayer
                    .padding(.top, 60)

                if let map = selectedMapForTooltip {
                    tooltipOverlay(for: map)
                        .padding(.top, 60)
                }

                VStack {
                    topBar
                    
                    if let firstMap = appState.maps.first {
                        areaTitle(area: firstMap.area)
                    }

                    Spacer()

                    if appState.bookingStatus != .unbooked {
                        FloatingBottomCard(appState: appState) {
                            guard let booked = appState.bookedMap else { return }
                            if appState.bookingStatus == .ongoing {
                                path.append(.ongoingItinerary)
                            } else {
                                detailMap = booked
                                showTourDetails = true
                            }
                        }
                        .padding(.bottom, 24)
                    }
                }

                testingControls

                if showTourDetails, let map = detailMap {
                    TourDetailsPopup(
                        appState: appState,
                        map: map,
                        isPresented: $showTourDetails,
                        path: $path
                    )
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .profile:
                    ProfileView()
                case .ongoingItinerary:
                    LoginView()
                case .checkAvailability(let map):
                    CheckAvailabilityView(appState: appState, map: map, path: $path)
                }
            }
            .navigationBarBackButtonHidden(false)
        }
    }

    private var backgroundMap: some View {
            Color(.systemGray6)
                .overlay(
                    Image("mapBackground")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.7)
                )
                .ignoresSafeArea()
        }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                path.append(.profile)
            } label: {
                Circle()
                    .strokeBorder(Color.orange, lineWidth: 3)
                    .background(Circle().fill(Color.gray.opacity(0.3)))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    )
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private func areaTitle(area: String) -> some View {
            Text(area)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 100)
        }

    // MARK: - Map Cards
    private var mapCardsLayer: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(appState.maps.enumerated()), id: \.element.id) { index, map in
                    if mapLayouts.indices.contains(index) {
                        let layout = mapLayouts[index]
                        mapCard(for: map)
                            .frame(
                                width: geo.size.width * layout.widthFraction,
                                height: geo.size.height * layout.heightFraction
                            )
                            .position(
                                x: geo.size.width * layout.xFraction,
                                y: geo.size.height * layout.yFraction
                            )
                    }
                }
            }
        }
    }

    private func mapCard(for map: TourMap) -> some View {
            let isBooked = map.id == appState.bookedMapId
            let fogged = fogState(for: map, isBooked: isBooked)
            let greyed = greyState(for: map, isBooked: isBooked)

            let targetFogAsset: String
            switch map.imageName {
            case "hypeRadarCover": targetFogAsset = "fogMap1"
            case "localsChoiceCover": targetFogAsset = "fogMap2"
            case "sweetTrailCover": targetFogAsset = "fogMap3"
            default: targetFogAsset = "fogMap1"
            }

            return Button {
                handleTap(on: map, isBooked: isBooked)
            } label: {
                FoggyMapView(isFogged: fogged, fogImageName: targetFogAsset) {
                    Image(map.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .saturation(greyed ? 0 : 1)
                }
            }
            .buttonStyle(.plain)
            .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 4)
        }

    private func fogState(for map: TourMap, isBooked: Bool) -> Bool {
        switch appState.bookingStatus {
        case .unbooked:
            return true
        case .upcoming:
            return true
        case .ongoing:
            return !isBooked
        }
    }

    private func greyState(for map: TourMap, isBooked: Bool) -> Bool {
        switch appState.bookingStatus {
        case .unbooked:
            return false
        case .upcoming, .ongoing:
            return !isBooked
        }
    }

    private func handleTap(on map: TourMap, isBooked: Bool) {
        if appState.bookingStatus != .unbooked && !isBooked {
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedMapForTooltip = (selectedMapForTooltip?.id == map.id) ? nil : map
        }
    }

    // MARK: - Tooltip
    @ViewBuilder
    private func tooltipOverlay(for map: TourMap) -> some View {
        if let index = appState.maps.firstIndex(where: { $0.id == map.id }),
           mapLayouts.indices.contains(index) {
            let layout = mapLayouts[index]
            let isBooked = map.id == appState.bookedMapId

            GeometryReader { geo in
                CustomTooltipBubble(
                    title: map.title,
                    points: map.pointCost,
                    badge: badgeText(isBooked: isBooked),
                    subtitle: subtitleText(isBooked: isBooked),
                    buttonTitle: "View"
                ) {
                    detailMap = map
                    showTourDetails = true
                    selectedMapForTooltip = nil
                }
                .frame(width: 180)
                .position(
                    x: geo.size.width * layout.xFraction,
                    y: geo.size.height * layout.yFraction
                )
            }
        }
    }

    private func badgeText(isBooked: Bool) -> String? {
        guard isBooked else { return nil }
        switch appState.bookingStatus {
        case .upcoming: return "Up coming"
        case .ongoing: return "Ongoing"
        case .unbooked: return nil
        }
    }

    private func subtitleText(isBooked: Bool) -> String? {
        guard isBooked, let date = appState.selectedDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Testing Controls
    private var testingControls: some View {
        VStack {
            HStack {
                Menu {
                    Button("Reset to Unbooked") {
                        appState.cancelBooking()
                    }
                    Button("Simulate Upcoming Booking") {
                        if let first = appState.maps.first {
                            appState.confirmBooking(
                                mapId: first.id,
                                date: Date().addingTimeInterval(60 * 60 * 24 * 7)
                            )
                        }
                    }
                    Button("Trigger D-Day (Ongoing)") {
                        appState.triggerDDay()
                    }
                } label: {
                    Image(systemName: "hammer.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.orange)
                        .padding(6)
                        .background(Circle().fill(Color.white))
                        .shadow(color: .black.opacity(0.15), radius: 4)
                }
                Spacer()
            }
            .padding(.leading)
            .padding(.top, 60)
            Spacer()
        }
    }
}

#Preview {
    HomepageView()
}
