import SwiftUI
import PhotosUI // 1. Import the framework

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var draftUser: User
    
    // 2. Add State for the photo picker
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var customProfileImage: Image? = nil
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _draftUser = State(initialValue: viewModel.user)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                CenterView {
                    // Profile Picture
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                        ZStack(alignment: .bottomTrailing) {
                            
                            // 🔥 CHANGED: Now looking at draftUser instead of viewModel.user
                            if let imageData = draftUser.customImageData,
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
                                
                                // 🔥 CHANGED: Now looking at draftUser instead of viewModel.user
                                // Show the default asset image
                                Image(draftUser.profileImageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .foregroundColor(.gray)
                                    .clipShape(Circle())
                                    .padding(4)
                                    .background(Circle().stroke(Color.orange, lineWidth: 2))
                            }
                            
                            Image(systemName: "camera.fill")
                                .font(.caption)
                                .foregroundColor(.black)
                                .padding(6)
                                .background(Circle().fill(Color.white))
                                .shadow(radius: 2)
                                .offset(x: -5, y: -5)
                        }
                    }
                }
                .padding(.bottom, 10)
                .padding(.top, 20)
                // 4. Load the image data when the user picks a photo
                .onChange(of: selectedPhotoItem) { newItem in
                    Task {
                        // Attempt to load the selected image as raw Data
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            // Convert it to a SwiftUI Image so we can display it
                            customProfileImage = Image(uiImage: uiImage)
                            
                            draftUser.customImageData = data
                        }
                    }
                }
                
                // Nickname Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nickname").font(.subheadline).bold()
                    TextField("Enter nickname", text: $draftUser.nickname)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))
                }
                
                // Custom Gender Dropdown
                CustomDropdown(title: "Gender", selection: $draftUser.gender)
                
                // Interests
                InterestSelectionView(selectedInterests: $draftUser.interests)
                
                CustomDropdown(title: "Personality", selection: $draftUser.personality)
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.updateProfile(with: draftUser)
                    dismiss()
                }) {
                    Image(systemName: "checkmark")
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
        }
    }
}

struct CenterView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        HStack {
            Spacer()
            content
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView(viewModel: ProfileViewModel())
    }
}
