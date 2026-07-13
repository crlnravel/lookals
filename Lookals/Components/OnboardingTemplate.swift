import SwiftUI

/// Shared template for the Orange Background + White Bottom Card
struct OnboardingTemplate<Content: View>: View {
    let title: String
    let subtitle: String
    let bgImageName: String
    var bgImageSize: CGFloat? = nil
    let onBack: () -> Void
    
    var circleYOffset: CGFloat = 220
    
    @ViewBuilder let content: Content
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.orange.ignoresSafeArea()
            
            if let size = bgImageSize {
                VStack {
                    Spacer()
                    Image(bgImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size)
                    Spacer()
                }
                .padding(.bottom, 400)
            } else {
              
                Image(bgImageName)
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(1.2)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.8))
                    .padding(.bottom, 20)
                
                content
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color.white
                    .frame(width: 1000, height: 1000)
                    .clipShape(Circle())
                    .offset(y: circleYOffset)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct PrimaryButtonLabel: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.headline.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.orange)
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        OnboardingTemplate(
            title: "Sample Title",
            subtitle: "Sample subtitle goes right here.",
            bgImageName: "profileSetupBg",
            onBack: {},
            circleYOffset: 220,
        ) {
            PrimaryButtonLabel(title: "Sample Button")
        }
    }
}
