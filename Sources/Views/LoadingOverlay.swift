import SwiftUI

struct LoadingOverlay: View {
    let message: String

    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .background(.ultraThinMaterial)

            // Loading content
            VStack(spacing: 24) {
                // Gradient spinner background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)

                    ProgressView()
                        .scaleEffect(1.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }

                Text(message)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(48)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThickMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            )
        }
    }
}
