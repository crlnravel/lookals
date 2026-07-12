import SwiftUI

struct PersonalityView: View {
    @Binding var path: [OnboardingStep]
    @State private var selectedPersonality: String = "Select Personality"
    
    let personalities = ["Select Personality", "Introvert", "Extrovert", "Ambivert"]
    
    var body: some View {
        OnboardingTemplate(
            title: "What's your personality?",
            subtitle: "This helps us find the best Lookals connections for you.",
            bgImageName: "profileSetupBg",
            onBack: { path.removeLast() },
            circleYOffset: 250,
        ) {
            Menu {
                ForEach(personalities.dropFirst(), id: \.self) { trait in
                    Button(trait) {
                        selectedPersonality = trait
                    }
                }
            } label: {
                HStack {
                    Text(selectedPersonality)
                        .foregroundColor(selectedPersonality == "Select Personality" ? .gray : .black)
                    Spacer()
                    Image(systemName: "arrowtriangle.down.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.bottom, 100)
            
            
            Button {
                path.append(.location)
            } label: {
                PrimaryButtonLabel(title: "Next")
            }
        }
    }
}

#Preview {
    NavigationStack {
        PersonalityView(path: .constant([]))
    }
}
