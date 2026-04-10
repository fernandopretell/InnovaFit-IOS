import SwiftUI
import FirebaseAuth

/// Vista para registrar al usuario tras la verificación
struct RegisterView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var name: String = ""
    @State private var phoneNumber: String = ""
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -15, to: Date()) ?? Date()
    @State private var selectedGym: Gym?
    @State private var isMale: Bool = true
    @State private var weightValue: Double = 60.0
    @State private var heightValue: Double = 170.0 // en cm
    @State private var medicalConditions: String = ""
    @State private var showGymPicker = false

    private var isGoogleAuth: Bool {
        !viewModel.pendingGoogleName.isEmpty
    }

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

                    // TELEFONO (solo para usuarios Google)
                    if isGoogleAuth {
                        ZStack(alignment: .leading) {
                            if phoneNumber.isEmpty {
                                Text("Numero de telefono")
                                    .foregroundColor(.textPlaceholder)
                                    .font(.system(size: 16))
                                    .padding(.leading, 16)
                            }

                            TextField("", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .padding(.horizontal, 16)
                                .frame(height: 48)
                                .font(.system(size: 16))
                                .foregroundColor(.textTitle)
                        }
                        .background(Color.backgroundFields)
                        .cornerRadius(12)
                    }

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
                    Button {
                        showGymPicker = true
                    } label: {
                        HStack {
                            Text(selectedGym?.name ?? "Seleccionar gimnasio")
                                .font(.system(size: 16))
                                .foregroundColor(selectedGym == nil ? .textPlaceholder : .textTitle)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.textPlaceholder)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(Color.backgroundFields)
                        .cornerRadius(12)
                    }

                    // GENERO
                    GenderToggleButton(isMale: $isMale)

                    // CONDICIONES MÉDICAS (opcional)
                    ZStack(alignment: .topLeading) {
                        if medicalConditions.isEmpty {
                            Text("Lesiones o condiciones médicas (opcional)")
                                .foregroundColor(.textPlaceholder)
                                .font(.system(size: 16))
                                .padding(.leading, 16)
                                .padding(.top, 14)
                        }

                        TextEditor(text: $medicalConditions)
                            .font(.system(size: 16))
                            .foregroundColor(.textTitle)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(minHeight: 80, maxHeight: 120)
                    }
                    .background(Color.backgroundFields)
                    .cornerRadius(12)

                    // BOTON DE REGISTRO
                    Button(action: {
                        if let gym = selectedGym {
                            let phone: String
                            if isGoogleAuth {
                                phone = phoneNumber.trimmingCharacters(in: .whitespaces)
                            } else {
                                phone = Auth.auth().currentUser?.phoneNumber ?? ""
                            }
                            let edadCalculada = calcularEdad(from: birthDate)
                            let gender: String = isMale ? "M" : "F"

                            viewModel.registerUser(
                                name: name,
                                age: edadCalculada,
                                gender: gender,
                                gym: gym,
                                phone: phone,
                                weight: weightValue,
                                height: heightValue,
                                medicalConditions: medicalConditions.trimmingCharacters(in: .whitespacesAndNewlines)
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
                    .disabled(name.isEmpty || selectedGym == nil || (isGoogleAuth && phoneNumber.isEmpty))
                    .padding(.top, 10)
                }
                .padding()
            }
            .background(Color.white)
            .fullScreenCover(isPresented: $showGymPicker) {
                GymPickerView(
                    gyms: viewModel.gyms,
                    selectedGym: selectedGym,
                    onSelect: { gym in
                        selectedGym = gym
                        showGymPicker = false
                    },
                    onDismiss: { showGymPicker = false }
                )
            }
        }
        .onAppear {
            // Pre-llenar nombre si viene de Google
            if !viewModel.pendingGoogleName.isEmpty && name.isEmpty {
                name = viewModel.pendingGoogleName
            }
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



// MARK: - Gym Picker (Full Screen)

struct GymPickerView: View {
    let gyms: [Gym]
    let selectedGym: Gym?
    let onSelect: (Gym) -> Void
    let onDismiss: () -> Void

    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    private var filteredGyms: [Gym] {
        if searchText.isEmpty { return gyms }
        return gyms.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#171712"))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: "#F4F2E6"))
                        .clipShape(Circle())
                }

                Spacer()

                Text("Selecciona tu gimnasio")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color(hex: "#171712"))

                Spacer()

                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)

                TextField("Buscar gimnasio...", text: $searchText)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#171712"))
                    .focused($isSearchFocused)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(Color(hex: "#F4F2E6"))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)

            Divider()

            // Gym list
            if filteredGyms.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "building.2")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.4))
                    Text("No se encontraron gimnasios")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredGyms) { gym in
                            GymPickerRow(
                                gym: gym,
                                isSelected: selectedGym?.id == gym.id,
                                onTap: { onSelect(gym) }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .preferredColorScheme(.light)
        .onAppear { isSearchFocused = true }
    }
}

private struct GymPickerRow: View {
    let gym: Gym
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Gym icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: gym.safeColor).opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: gym.safeColor))
                }

                // Gym info
                VStack(alignment: .leading, spacing: 3) {
                    Text(gym.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "#171712"))
                        .lineLimit(1)

                    if !gym.address.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 11))
                            Text(gym.address)
                                .font(.system(size: 13))
                                .lineLimit(1)
                        }
                        .foregroundColor(Color(hex: "#171712").opacity(0.55))
                    }
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(hex: "#FDD835"))
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 4)
        }

        Divider()
            .padding(.leading, 66)
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
