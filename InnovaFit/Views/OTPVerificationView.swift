import SwiftUI

/// Vista para ingresar el código OTP recibido
struct OTPVerificationView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Verificación")
                .font(.title)
                .foregroundColor(Color(hex: "#111111"))

            TextField("Código", text: $viewModel.otpCode)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#00C2FF"), lineWidth: 1)
                )

            Button("Verificar") {
                viewModel.verifyOTP()
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
