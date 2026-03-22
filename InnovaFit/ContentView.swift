import SwiftUI
/// Maneja la navegación de autenticación utilizando `AuthViewModel`
struct ContentView: View {
    @StateObject var authViewModel = AuthViewModel()

    var body: some View {
        switch authViewModel.authState {
        case .splash:
            SplashView()
        case .login:
            NavigationStack {
                LoginView(viewModel: authViewModel)
            }
        case .otp:
            NavigationStack {
                OTPVerificationView(viewModel: authViewModel)
            }
        case .register:
            NavigationStack {
                RegisterView(viewModel: authViewModel)
            }
        case .home:
            MainTabView(viewModel: authViewModel)
        }
    }
}
