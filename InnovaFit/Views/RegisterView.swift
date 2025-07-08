import SwiftUI
import FirebaseAuth

/// Vista para registrar al usuario tras la verificación
struct RegisterView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var name: String = ""
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -15, to: Date()) ?? Date()
    @State private var selectedGym: Gym?
    @State private var isMale: Bool = true
    @State private var weightValue: Double = 60.0
    @State private var heightValue: Double = 170.0 // en cm

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Registro")
                        .font(.title.bold())
                        .foregroundColor(Color.textTitle)

                    // NOMBRE
                    ZStack(alignment: .leading) {
                        if name.isEmpty {
                            Text("Nombre")
                                .foregroundColor(.textPlaceholder)
                                .font(.system(size: 16))
                                .padding(.leading, 16)
                        }

                        TextField("", text: $name)
                            .padding(.horizontal, 16)
                            .frame(height: 48)
                            .font(.system(size: 16))
                            .foregroundColor(.textTitle)
                    }
                    .background(Color.backgroundFields)
                    .cornerRadius(12)


                    // FECHA DE NACIMIENTO
                    DatePicker("Fecha de nacimiento", selection: $birthDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding()
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .background(Color.backgroundFields)
                        .cornerRadius(12)
                        .foregroundColor(Color.textTitle)
                        .environment(\.locale, Locale(identifier: "es"))

                    VStack(spacing: 16) {
                        // PESO
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Peso")
                                .font(.subheadline)
                                .foregroundColor(.textBody)

                            Stepper(value: $weightValue, in: 20...200, step: 0.5) {
                                Text("\(weightValue, specifier: "%.1f") kg")
                                    .foregroundColor(.textTitle)
                            }
                            .tint(Color(hex: "#A18F45"))
                        }
                        .padding()
                        .background(Color.backgroundFields)
                        .cornerRadius(12)

                        // TALLA
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Talla")
                                .font(.subheadline)
                                .foregroundColor(.textBody)

                            Stepper(value: $heightValue, in: 100...250, step: 1) {
                                Text("\(Int(heightValue)) cm")
                                    .foregroundColor(.textTitle)
                            }
                        }
                        .padding()
                        .background(Color.backgroundFields)
                        .cornerRadius(12)
                    }

                    // SELECCIONAR GIMNASIO
                    Menu {
                        ForEach(viewModel.gyms) { gym in
                            Button(action: {
                                selectedGym = gym
                            }) {
                                Text(gym.name)
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.backgroundFields)
                                .frame(height: 48)

                            Text(selectedGym?.name ?? "Seleccionar gimnasio")
                                .foregroundColor(selectedGym == nil ? .textPlaceholder : .textTitle)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    // GÉNERO
                    GenderToggleButton(isMale: $isMale)

                    // BOTÓN DE REGISTRO
                    Button(action: {
                        if let gym = selectedGym,
                           let phone = Auth.auth().currentUser?.phoneNumber {
                            let edadCalculada = calcularEdad(from: birthDate)
                            let gender: String = isMale ? "M" : "F"

                            viewModel.registerUser(
                                name: name,
                                age: edadCalculada,
                                gender: gender,
                                gym: gym,
                                phone: phone,
                                weight: weightValue,
                                height: heightValue
                            )
                        }
                    }) {
                        Text("Registro")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.innovaYellow)
                            .cornerRadius(24)
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
            .background(Color.white)
        }
    }

    func calcularEdad(from fechaNacimiento: Date) -> Int {
        let calendar = Calendar.current
        let now = Date()
        return calendar.dateComponents([.year], from: fechaNacimiento, to: now).year ?? 0
    }
}


struct GenderToggleButton: View {
    @Binding var isMale: Bool
    var leftName: String = "Masculino"
    var rightName: String = "Femenino"

    var body: some View {
        ZStack(alignment: isMale ? .leading : .trailing) {
            // Fondo base
            Capsule()
                .fill(Color(hex: "#F6F4EC")) // fondo claro neutro
                .frame(height: 48)

            // Botón seleccionado
            Capsule()
                .fill(Color.white)
                .frame(width: UIScreen.main.bounds.width * 0.4, height: 44)
                .padding(4)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)
                .animation(.easeInOut(duration: 0.25), value: isMale)

            HStack {
                Text(leftName)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(isMale ? .black : Color(hex: "#9B9B9B"))
                    .fontWeight(isMale ? .bold : .regular)
                    .onTapGesture {
                        withAnimation { isMale = true }
                    }

                Text(rightName)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(!isMale ? .black : Color(hex: "#9B9B9B"))
                    .fontWeight(!isMale ? .bold : .regular)
                    .onTapGesture {
                        withAnimation { isMale = false }
                    }
            }
            .font(.system(size: 14))
        }
        .frame(height: 48)
        .cornerRadius(30)
    }
}



struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(viewModel: AuthViewModel())
            .previewDevice("iPhone 15")
            .previewDisplayName("RegisterView - Light")
            .preferredColorScheme(.light)
            .padding()
            .background(Color.white)
    }
}

