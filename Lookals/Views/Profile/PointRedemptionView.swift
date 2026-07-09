//
//  PointRedemptionView.swift
//  Lookals
//
//  Created by Kevin Halim on 08/07/26.
//

import SwiftUI

struct PointRedemptionView: View {
    @Environment(\.dismiss) var dismiss
    
    // observe user data
    @ObservedObject var profileViewModel: ProfileViewModel
    
    // observe screen state
    @StateObject private var viewModel: PointRedemptionViewModel
    
    init(profileViewModel: ProfileViewModel) {
        self.profileViewModel = profileViewModel
        _viewModel = StateObject(wrappedValue: PointRedemptionViewModel(profileViewModel: profileViewModel))
    }
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 0) {
                // buat test bisa redeem atau tidak
                DebugPointsView(viewModel: viewModel)
                
                // tab available coupons & my coupons
                PointRedemptionTabBar(viewModel: viewModel, profileViewModel: profileViewModel)
                if viewModel.selectedTab == .available {
                    AvailableCouponsList(viewModel: viewModel)
                } else {
                    MyCouponsList(viewModel: viewModel, profileViewModel: profileViewModel)
                }
                
                Spacer()
            }
            
            // pop up penggunaan coupon
            if let coupon = viewModel.selectedCouponForOverlay {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { viewModel.selectedCouponForOverlay = nil }
                    }
                
                CouponOverlayView(coupon: coupon) {
                    withAnimation { viewModel.selectedCouponForOverlay = nil }
                }
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .navigationTitle("Point Redemption")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            PointRedemptionToolbar(dismiss: dismiss, profileViewModel: profileViewModel)
        }
        .alert(viewModel.alertTitle(), isPresented: Binding(
            get: { viewModel.activeAlert != nil },
            set: { if !$0 { viewModel.activeAlert = nil } }
        )) {
            PointRedemptionAlertButtons(viewModel: viewModel)
        } message: {
            Text(viewModel.alertMessage())
        }
    }
}


struct DebugPointsView: View {
    @ObservedObject var viewModel: PointRedemptionViewModel
    
    var body: some View {
        HStack {
            Button("+ 50 Points") { viewModel.addDebugPoints() }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            Button("Reset to 0") { viewModel.resetDebugPoints() }
                .buttonStyle(.borderedProminent)
                .tint(.red)
        }
        .padding(.top, 10)
    }
}

struct PointRedemptionTabBar: View {
    @ObservedObject var viewModel: PointRedemptionViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            tabButton(title: "Available Coupons", tab: .available)
            tabButton(title: "My Coupons", tab: .myCoupons)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
    }
    
    private func tabButton(title: String, tab: PointRedemptionTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) { viewModel.selectedTab = tab }
        }) {
            VStack(spacing: 10) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(viewModel.selectedTab == tab ? .bold : .regular)
                    .foregroundColor(viewModel.selectedTab == tab ? .black : .gray)
                    .overlay(
                        Group {
                            if tab == .myCoupons && !profileViewModel.user.myCoupons.isEmpty {
                                Text("\(profileViewModel.user.myCoupons.count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Circle().fill(Color.orange))
                                    .offset(x: -26)
                            }
                        },
                        alignment: .leading
                    )
                
                Rectangle()
                    .fill(viewModel.selectedTab == tab ? Color.black : Color.gray.opacity(0.2))
                    .frame(height: 2)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct AvailableCouponsList: View {
    @ObservedObject var viewModel: PointRedemptionViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(dummyCoupons) { coupon in
                    CouponCard(coupon: coupon, isOwned: false) {
                        viewModel.attemptRedemption(for: coupon)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

struct MyCouponsList: View {
    @ObservedObject var viewModel: PointRedemptionViewModel
    @ObservedObject var profileViewModel: ProfileViewModel
    
    var body: some View {
        Group {
            if profileViewModel.user.myCoupons.isEmpty {
                VStack {
                    Spacer()
                    Text("You currently have no\ncoupon yet.")
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    Spacer()
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(profileViewModel.user.myCoupons) { coupon in
                            CouponCard(coupon: coupon, isOwned: true) {}
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        viewModel.selectedCouponForOverlay = coupon
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

struct PointRedemptionAlertButtons: View {
    @ObservedObject var viewModel: PointRedemptionViewModel
    
    var body: some View {
        switch viewModel.activeAlert {
        case .success:
            Button("OK") { viewModel.activeAlert = nil }
                .foregroundColor(.gray)
            Button("See Coupon") {
                withAnimation { viewModel.selectedTab = .myCoupons }
                viewModel.activeAlert = nil
            }
            .foregroundColor(.blue)
        case .insufficient:
            Button("OK") { viewModel.activeAlert = nil }
                .foregroundColor(.gray)
        case nil:
            EmptyView()
        }
    }
}

struct PointRedemptionToolbar: ToolbarContent {
    let dismiss: DismissAction
    @ObservedObject var profileViewModel: ProfileViewModel
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(6)
                    .background(Circle().fill(Color.orange))
                
                Text("\(profileViewModel.user.points)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }.padding(.horizontal, 6)
        }
    }
}

// MARK: - Overlay Component

struct CouponOverlayView: View {
    let coupon: Coupon
    let onClose: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Image(coupon.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipped()
                
                VStack {
                    Spacer()
                    LinearGradient(gradient: Gradient(colors: [.white.opacity(0), .white]), startPoint: .top, endPoint: .bottom)
                        .frame(height: 40)
                }
                
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.8)))
                }
                .padding(16)
            }
            .frame(height: 220)
            
            VStack(alignment: .leading, spacing: 16) {
                Text(coupon.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.black)
                        .padding(.top, 2)
                    
                    Text(coupon.description)
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.8))
                        .lineLimit(2)
                }
                
                VStack {
                    Image(systemName: "barcode")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 80)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
            .padding(24)
            .background(Color.white)
        }
        .background(Color.white)
        .cornerRadius(24)
        .padding(.horizontal, 32)
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 10)
    }
}

#Preview {
    NavigationStack {
        PointRedemptionView(profileViewModel: ProfileViewModel())
    }
}
