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
    case memories
    case gallery
}

struct HomepageView: View {
    @StateObject private var appState = HomeStateManager()
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var memoriesViewModel: MemoriesViewModel
    
    @State private var selectedMapForTooltip: TourMap? = nil
    @State private var detailMap: TourMap? = nil
    @State private var showTourDetails = false
    @State private var tapLocation: CGPoint = .zero
    @State private var path = NavigationPath()

    @MainActor
    init() {
        self.init(memoryPhotoService: Self.defaultMemoryPhotoService)
    }

    @MainActor
    init(memoryPhotoService: any MemoryPhotoServicing) {
        _memoriesViewModel = State(
            initialValue: MemoriesViewModel(memoryPhotoService: memoryPhotoService)
        )
    }

    private struct MapLayout {
        let xFraction: CGFloat
        let yFraction: CGFloat
        let widthFraction: CGFloat
        let heightFraction: CGFloat
    }

    private let mapLayouts: [MapLayout] = [
        MapLayout(xFraction: 0.29, yFraction: 0.48, widthFraction: 0.44, heightFraction: 0.4),
        MapLayout(xFraction: 0.75, yFraction: 0.37, widthFraction: 0.44, heightFraction: 0.34),
        MapLayout(xFraction: 0.65, yFraction: 0.61, widthFraction: 0.30, heightFraction: 0.34)
    ]

    var body: some View {
        NavigationStack(path: $path) {
            ZStack(alignment: .top) {
                backgroundMap.overlay{ Image("Fog") }
                
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.2)) { selectedMapForTooltip = nil }
                    }
                
                mapCardsLayer
                
                if appState.hasCompletedTour {
                    MapPhotoPinView(position: CGPoint(x: 100, y: 400)) {
                        openCurrentTourMemories()
                    }
                    .zIndex(20)
                }

                if appState.bookingStatus == .ongoing {
                    ongoingMemoryCameraButton
                        .zIndex(30)
                }

                VStack {
                    customTopBar
                    
                    if let firstMap = appState.maps.first {
                        areaTitle(area: firstMap.area).padding(.top, 5)
                    }
                    Spacer()
                    if appState.bookingStatus != .unbooked {
                        FloatingBottomCard(appState: appState) {
                            guard let booked = appState.bookedMap else { return }
                            if appState.bookingStatus == .ongoing {
                                path.append(HomeRoute.ongoingItinerary)
                            } else {
                                detailMap = booked
                                showTourDetails = true
                            }
                        }
                    }
                }
                
                testingControls
                
                if let map = selectedMapForTooltip { tooltipOverlay(for: map).zIndex(50) }
                
                if showTourDetails, let map = detailMap {
                    TourDetailsPopup(appState: appState, map: map, isPresented: $showTourDetails, path: $path)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                        .zIndex(100)
                }
            }
            .onAppear {
                prepareCurrentTourMemoryAlbum()
            }
            .coordinateSpace(name: "HomeScreenSpace")
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .profile: ProfileView()
                case .ongoingItinerary: LoginView()
                case .checkAvailability(let map): CheckAvailabilityView(appState: appState, map: map, path: $path)
                case .memories, .gallery: MemoriesOverviewView(viewModel: memoriesViewModel)
                }
            }
        }
    }
    
    private var customTopBar: some View {
        HStack {
            Button { print("Poin diklik") } label: {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Circle().fill(Color.orange))
                    Text("\(profileViewModel.user.points)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding(.leading, 12)
                .padding(.trailing, 12)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                )
            }
            .buttonStyle(.plain)

            Spacer()

            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(height: 44)

            Spacer()

            Button {
                path.append(HomeRoute.profile)
            } label: {
                ZStack {
                    Group {
                        if let imageData = profileViewModel.user.customImageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage).resizable().scaledToFill()
                        } else {
                            Image(profileViewModel.user.profileImageName).resizable().scaledToFill()
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())

                    Image(profileViewModel.user.level.badgeImageName)
                        .resizable()
                        .scaledToFit()
                    .frame(height: 44)
                }
            }
        }
    }

    private static var defaultMemoryPhotoService: any MemoryPhotoServicing {
        #if LOOKALS_CLOUDKIT
        CloudMemoryService.shared
        #else
        LocalMemoryPhotoService.shared
        #endif
    }

    private var currentMemoryMap: TourMap? {
        if let bookedMap = appState.bookedMap {
            return bookedMap
        }

        return appState.completedMapIds
            .reversed()
            .compactMap { completedMapId in
                appState.maps.first { $0.id == completedMapId }
            }
            .first ?? appState.maps.first
    }

    @discardableResult
    private func prepareCurrentTourMemoryAlbum() -> UUID? {
        guard let currentMemoryMap else {
            return memoriesViewModel.albums.first?.id
        }

        return memoriesViewModel.prepareAlbum(for: currentMemoryMap)
    }

    private func openCurrentTourMemories() {
        prepareCurrentTourMemoryAlbum()
        path.append(HomeRoute.gallery)
    }

    private var ongoingMemoryCameraButton: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                Button {
                    guard let albumID = prepareCurrentTourMemoryAlbum() else { return }
                    path.append(MemoriesRoute.addMemory(albumID))
                } label: {
                    Image(systemName: "camera.fill")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.orange))
                        .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
                }
                .accessibilityLabel("Add memory")
            }
            .padding(.trailing, 24)
            .padding(.bottom, 164)
        }
        .padding(.horizontal, 16)
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
    
    private func areaTitle(area: String) -> some View {
            Text(area)
            .font(.system(size: 27, weight: .heavy))
                .lineHeight(.exact(points: 32))
                // bikin outline
                .shadow(color: .white, radius: 0.8, x: 2, y: 2)
                .shadow(color: .white, radius: 0.8, x: -2, y: -2)
                .shadow(color: .white, radius: 0.8, x: 2, y: -2)
                .shadow(color: .white, radius: 0.8, x: -2, y: 2)
                .shadow(color: .white, radius: 0.8, x: 0, y: 2)
                .shadow(color: .white, radius: 0.8, x: 0, y: -2)
                .shadow(color: .white, radius: 0.8, x: 2, y: 0)
                .shadow(color: .white, radius: 0.8, x: -2, y: 0)
        
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .shadow(radius: 2, x: 1, y: 2)
                .padding(.horizontal, 110)
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

            return FoggyMapView(isFogged: fogged, fogImageName: targetFogAsset) {
                Image(map.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .saturation(greyed ? 0 : 1)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 4)
            }
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .named("HomeScreenSpace")) { location in
                handleTap(on: map, isBooked: isBooked, location: location)
            }
        }

    private func fogState(for map: TourMap, isBooked: Bool) -> Bool {
            if appState.completedMapIds.contains(map.id) {
                return false
            }
            
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
            if appState.completedMapIds.contains(map.id) {
                return false
            }
            
            switch appState.bookingStatus {
            case .unbooked:
                return false
            case .upcoming, .ongoing:
                return !isBooked
            }
        }

    private func handleTap(on map: TourMap, isBooked: Bool, location: CGPoint) {
        if appState.bookingStatus != .unbooked && !isBooked {
            return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if selectedMapForTooltip?.id == map.id {
                selectedMapForTooltip = nil
            } else {
                selectedMapForTooltip = map
                tapLocation = location
            }
        }
    }

    // MARK: - Tooltip
    @ViewBuilder
    private func tooltipOverlay(for map: TourMap) -> some View {
        let isBooked = map.id == appState.bookedMapId

        GeometryReader { _ in
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
            .position(x: tapLocation.x, y: tapLocation.y - 70)
            .id(map.id)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
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
                    Button("Finish Tour (Show Memory)") {
                        appState.finishTour()
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
