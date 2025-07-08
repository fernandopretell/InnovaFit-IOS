import SwiftUI

/// Vista para ingresar el código OTP recibido
struct OTPVerificationView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 24) {
            Text("Verificación")
                .font(.title)
                .bold()
                .foregroundColor(Color.textTitle)
            
            Text("Te enviaremos un código por SMS.")
                .font(.subheadline)
                .bold()
                .foregroundColor(Color.textSubtitle)

            ZStack(alignment: .leading) {
                if viewModel.otpCode.isEmpty {
                    Text("Código")
                        .foregroundColor(.textPlaceholder) // define este color
                        .padding(.leading, 16)
                        .font(.system(size: 16))
                }

                TextField("", text: $viewModel.otpCode)
                    .keyboardType(.numberPad)
                    .padding()
                    .background(Color.white)
                    .foregroundColor(Color.black)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.accentColor, lineWidth: 1)
                    )
            }


            Button(action: {
                viewModel.verifyOTP()
            }) {
                Text("Verificar")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(Color.textTitle)
                    .cornerRadius(28)
            }

            
            Spacer()
        }
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color.white)
    }
}

struct OTPVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        OTPVerificationView(viewModel: MockAuthViewModel())
            .previewDevice("iPhone 15")
            .previewDisplayName("OTP Verification")
            .padding()
            .background(Color.white)
    }
}

class MockAuthViewModel: AuthViewModel {
    override init() {
        super.init()
        self.otpCode = "123456"
    }

    override func verifyOTP() {
        print("🧪 Simulando verificación de OTP...")
    }
}


