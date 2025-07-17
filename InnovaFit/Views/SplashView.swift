import SwiftUI

/// Simple splash view while determining authentication state
struct SplashView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                .scaleEffect(1.5)
        }
    }
}

#Preview {
    SplashView()
}
