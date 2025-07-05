import SwiftUI

/// Vista para ingresar el número de celular y solicitar el OTP
struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Iniciar sesión")
                .font(.title)
                .foregroundColor(Color(hex: "#111111"))

            TextField("Número de celular", text: $viewModel.phoneNumber)
                .keyboardType(.phonePad)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#00C2FF"), lineWidth: 1)
                )

            Button("Enviar código") {
                viewModel.sendOTP()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(hex: "#00C2FF"))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
        .background(Color.white)
    }
}
