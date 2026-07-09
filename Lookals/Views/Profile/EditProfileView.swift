import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    
    @State private var draftUser: User
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _draftUser = State(initialValue: viewModel.user)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Profile Image
                CenterView {
                    ZStack(alignment: .bottomTrailing) {
                        Image(draftUser.profileImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                            .clipShape(Circle())
                        
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .padding(6)
                            .background(Circle().fill(Color.white))
                            .shadow(radius: 2)
                            .offset(x: -5, y: -5)
                    }
                }
                .padding(.bottom, 10)
                .padding(.top, 20)
                
                // Nickname Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nickname").font(.subheadline).bold()
                    TextField("Enter nickname", text: $draftUser.nickname)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3)))
                }
                
                // Custom Gender Dropdown (Figma Style)
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
