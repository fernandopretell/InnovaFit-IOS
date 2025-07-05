import SwiftUI

/// Maneja la navegación de autenticación utilizando `AuthViewModel`
struct ContentView: View {
    @StateObject var authViewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            switch authViewModel.authState {
            case .login:
                LoginView(viewModel: authViewModel)
            case .otp:
                OTPVerificationView(viewModel: authViewModel)
            case .register:
                RegisterView(viewModel: authViewModel)
            case .home:
                HomeView(viewModel: authViewModel)
            }
        }
    }
}
