import SwiftUI

/// Vista para ingresar el número de celular y solicitar el OTP
struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @FocusState private var isPhoneFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            Text("Iniciar sesión")
                .font(.title)
                .bold()
                .foregroundColor(Color(hex: "#111111"))

            ZStack(alignment: .leading) {
                if viewModel.phoneNumber.isEmpty {
                    Text("Número de celular")
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
                    Text("Enviar código")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.textTitle)
                        .background(Color.accentColor)
                        .cornerRadius(28)
                }
            }
            .disabled(viewModel.isLoading)

            Spacer()
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.white)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                isPhoneFocused = true
            }
        }
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

