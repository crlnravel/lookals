import SwiftUI

struct LookalsFactPopup: View {
    let fact: LookalsFact
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            dimmedBackground
            factCard
        }
    }

    private var dimmedBackground: some View {
        Color.black.opacity(0.22)
            .ignoresSafeArea()
            .onTapGesture(perform: onDismiss)
    }

    private var factCard: some View {
        VStack(spacing: 0) {
            factImage
            factCopy
        }
        .frame(width: 320)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(alignment: .topLeading) {
            dismissButton
                .padding(16)
                .zIndex(1)
        }
        .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 12)
        .padding(.horizontal, 24)
        .accessibilityElement(children: .contain)
    }

    private var factImage: some View {
        Image(fact.imageName)
            .resizable()
            .scaledToFill()
            .frame(height: 200)
            .clipped()
            .overlay(alignment: .bottom) {
                factImageGradient
            }
    }

    private var factImageGradient: some View {
        LinearGradient(
            colors: [.clear, Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 88)
    }

    private var dismissButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close Lookals fact")
    }

    private var factCopy: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lookals Fact")
                .font(.system(size: 33, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .center)

            Text(fact.highlight)
                .font(.system(size: 16, weight: .regular))
                .padding(.top, 12)
                .foregroundStyle(.primary)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(fact.details)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.primary)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, minHeight: 300, maxHeight: 360, alignment: .top)
    }

}
