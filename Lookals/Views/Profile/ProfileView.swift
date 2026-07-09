import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                // Profile Info
                VStack(spacing: 8) {
                    if let imageData = viewModel.user.customImageData,
                        let uiImage = UIImage(data: imageData) {
                            
                        // Show the custom uploaded photo
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .padding(4)
                            .background(Circle().stroke(Color.orange, lineWidth: 2))
                        } else {
                            // Show the default asset image
                            Image(viewModel.user.profileImageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                                .clipShape(Circle())
                                .padding(4)
                                .background(Circle().stroke(Color.orange, lineWidth: 2))
                        }
                    
                    Text(viewModel.user.nickname)
                        .font(.title)
                        .fontWeight(.heavy)
                    
                    Text(viewModel.user.level.title)
                        .font(.headline)
                        .italic()
                        .foregroundColor(.orange)
                }
                .padding(.top, 20)
                
                // Progress Bar
                VStack(spacing: 6) {
                    // calculate progress bar
                    let currentProgress = min(Double(viewModel.user.points) / 1000.0, 1.0)
                    SegmentedProgressBar(progress: currentProgress)
                        .padding(.horizontal, 40)
                    
                    Text("You've reached \(viewModel.user.points) cumulative point!")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .italic()
                }
                
                // Menu List
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
            }
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

struct SegmentedProgressBar: View {
    var progress: Double // A value between 0.0 (empty) and 1.0 (full)
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 1. The Background (Gray Segments)
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                }
                
                // 2. The Foreground (Orange Fill)
                // Its width is a percentage of the total width based on the progress
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: max(0, geometry.size.width * CGFloat(progress)))
            }
            // 3. Mask the whole thing so the 2px gaps stay transparent!
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
