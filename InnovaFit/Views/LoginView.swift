import SwiftUI

/// Vista para ingresar el número de celular y solicitar el OTP
struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @FocusState private var isPhoneFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("Bienvenido a InnovaFit")
                .font(.title)
                .bold()
                .foregroundColor(Color(hex: "#111111"))

            Text("Inicia sesion para continuar")
                .font(.subheadline)
                .foregroundColor(.textPlaceholder)

            // Boton Google Sign-In
            Button(action: {
                viewModel.signInWithGoogle()
            }) {
                HStack(spacing: 12) {
                    Image("ic_google")
                        .resizable()
                        .frame(width: 20, height: 20)

                    Text("Continuar con Google")
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "#111111"))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            }
            .disabled(viewModel.isLoading)

            // Separador
            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)

                Text("o")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)

                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
            }

            // Campo telefono
            ZStack(alignment: .leading) {
                if viewModel.phoneNumber.isEmpty {
                    Text("Numero de celular")
                        .background(Color.white)
                        .foregroundColor(.textPlaceholder)
                        .padding(.leading, 16)
                        .font(.system(size: 16))
                }

                TextField("", text: $viewModel.phoneNumber)
                    .keyboardType(.phonePad)
                    .padding()
                    .foregroundColor(Color.black)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.textPlaceholder, lineWidth: 1)
                    )
                    .focused($isPhoneFocused)
            }

            Button(action: {
                viewModel.sendOTP()
            }) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(28)
                } else {
                    Text("Enviar codigo")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.textTitle)
                        .background(Color.accentColor)
                        .cornerRadius(28)
                }
            }
            .disabled(viewModel.isLoading || viewModel.phoneNumber.isEmpty)

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Text("Al continuar, aceptas nuestros terminos y condiciones")
                .font(.caption2)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
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
