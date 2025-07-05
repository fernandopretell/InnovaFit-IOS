import SwiftUI

/// Vista para registrar al usuario tras la verificación
struct RegisterView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var gender: Gender = .masculino
    @State private var selectedGym: Gym?

    var body: some View {
        VStack(spacing: 24) {
            Text("Registro")
                .font(.title)
                .foregroundColor(Color(hex: "#111111"))

            TextField("Nombre", text: $name)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#00C2FF"), lineWidth: 1)
                )

            TextField("Edad", text: $age)
                .keyboardType(.numberPad)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#00C2FF"), lineWidth: 1)
                )

            Picker("Género", selection: $gender) {
                ForEach(Gender.allCases) { g in
                    Text(g.rawValue.capitalized).tag(g)
                }
            }
            .pickerStyle(.segmented)

            Picker("Gimnasio", selection: $selectedGym) {
                ForEach(viewModel.gyms) { gym in
                    Text(gym.name).tag(Optional(gym))
                }
            }

            Button("Registrarse") {
                if let gym = selectedGym, let ageInt = Int(age) {
                    viewModel.registerUser(name: name, age: ageInt, gender: gender, gym: gym)
                }
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
