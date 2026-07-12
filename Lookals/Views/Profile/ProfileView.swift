import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
<<<<<<< HEAD
            VStack(spacing: 24) {
                
                // Profile Info
                VStack(spacing: 8) {
=======
        VStack(spacing: 24) {
            
            VStack(spacing: 8) {
                // Updated: Profile Picture with Badge Overlay
                ZStack {
>>>>>>> e026eedde09bde776821067af14b211a27fe60cf
                    if let imageData = viewModel.user.customImageData,
                       let uiImage = UIImage(data: imageData) {
                        
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        
                    } else {
                        Image(viewModel.user.profileImageName)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                            .clipShape(Circle())
                    }
                    
                    // Badge Overlay
                    Image(viewModel.user.level.badgeImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 148, height: 148)
                }
<<<<<<< HEAD
=======
                
                Text(viewModel.user.nickname)
                    .font(.title)
                    .fontWeight(.heavy)
                
                Text(viewModel.user.level.title)
                    .font(.headline)
                    .italic()
                    .foregroundColor(.orange)
            }
            
            // MARK: - Progress Bar
            VStack(spacing: 6) {
                // Updated: Calculate EXP progress
                let currentLevelExp = viewModel.user.exp % 200
                let currentProgress = min(Double(currentLevelExp) / 200.0, 1.0)
                
                SegmentedProgressBar(progress: currentProgress)
                    .padding(.horizontal, 40)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentProgress)
                
                // Updated: Total cumulative EXP display
                Text("You've reached \(viewModel.user.exp) cumulative points!")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .italic()
            }
            
            // MARK: - Menu List
            VStack(spacing: 0) {
                Divider()
                
                // Edit Profile
                NavigationLink(destination: EditProfileView(viewModel: viewModel)) {
                    menuRow(icon: "person.circle", title: "Edit Profile")
                }
                
                Divider()
                
                // History
                NavigationLink(destination: HistoryView()) {
                    menuRow(icon: "clock.arrow.circlepath", title: "History")
                }
                
                Divider()
                
                // Point Redemption
                NavigationLink(destination: PointRedemptionView(profileViewModel: viewModel)) {
                    menuRow(icon: "medal", title: "Point Redemption")
                }
                
                Divider()
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            // toolbar - back
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
            }
            
            // toolbar - display points
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Circle().fill(Color.orange))
                    
                    Text("\(viewModel.user.points)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }.padding(.horizontal, 6)
            }
>>>>>>> e026eedde09bde776821067af14b211a27fe60cf
        }
    }
    
    private func menuRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black)
                .frame(width: 30)
            Text(title)
                .foregroundColor(.black)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Updated Segmented Progress Bar
struct SegmentedProgressBar: View {
    var progress: Double // A value between 0.0 (empty) and 1.0 (full)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                }
                
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: max(0, geometry.size.width * CGFloat(progress)))
            }
            .mask {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Rectangle()
                    }
                }
            }
        }
        .frame(height: 18)
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
