import SwiftUI

/// Vista para ingresar el número de celular y solicitar el OTP
struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Iniciar sesión")
                .font(.title)
                .bold()
                .foregroundColor(Color(hex: "#111111"))

            TextField("Número de celular", text: $viewModel.phoneNumber)
                .keyboardType(.phonePad)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.textPlaceholder, lineWidth: 1)
                )

            Button("Enviar código") {
                viewModel.sendOTP()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.textTitle)
            .cornerRadius(28)
            .bold()
            
            Spacer()
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.white)
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: AuthViewModel())
            .previewDevice("iPhone 15")
            .previewDisplayName("LoginView - Light")
            .preferredColorScheme(.light)
            .padding()
            .background(Color.white)
    }
}

