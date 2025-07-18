import SwiftUI

/// Simple splash view while determining authentication state
struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Aquí el icono de la app (debes tener un asset llamado "AppLaunchIcon")
                Image("AppLogo1")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150)

                // El spinner
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    .scaleEffect(1.5)
            }
        }
    }
}

#Preview {
    SplashView()
}
