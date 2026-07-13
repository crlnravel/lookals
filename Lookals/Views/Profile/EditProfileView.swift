import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var draftUser: User
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var customProfileImage: Image? = nil
    
    @State private var isSaving: Bool = false
    
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
                            ZStack {
                                if let imageData = draftUser.customImageData,
                                   let uiImage = UIImage(data: imageData) {
                                    
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                    
                                } else {
                                    Image(draftUser.profileImageName)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.gray)
                                        .clipShape(Circle())
                                }
                                
                                // badge overlay
                                Image(draftUser.level.badgeImageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 148, height: 148)
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
                .onChange(of: selectedPhotoItem) { _, newItem in
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
                
                // Personality Dropdown
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
                    saveToCloudKit()
                }) {
                    if isSaving {
                        ProgressView() // Tampilkan loading saat upload
                    } else {
                        Image(systemName: "checkmark")
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
                .disabled(isSaving)
            }
        }
    }
    
    private func saveToCloudKit() {
            isSaving = true
                
            viewModel.updateProfile(with: draftUser)
      
            let personalityString = draftUser.personality.rawValue
            
            let interestsStringArray = draftUser.interests.map { $0.rawValue }
            
            CloudKitManager.shared.updateUserProfile(
                name: draftUser.nickname,
                personality: personalityString,
                interests: interestsStringArray,
                imageData: draftUser.customImageData
            ) { success in
                DispatchQueue.main.async {
                    isSaving = false
                    if success {
                        dismiss()
                    } else {
                        print("Gagal update ke CloudKit")
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
