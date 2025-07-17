import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @ObservedObject var viewModel: AuthViewModel
    @StateObject private var machineVM = MachineViewModel()

    // Nueva prop para navegación hacia MachineScreenContent2
    var onSelectMachine: (Machine, Gym) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let profile = viewModel.userProfile {
                    // 👤 Encabezado
                    HStack {
                        Text("Hola, \(profile.name) 👋")
                            .font(.title2.bold())
                            .foregroundColor(.textTitle)

                        Spacer()

                        Menu {
                            Button("Cerrar sesión", role: .destructive) {
                                viewModel.signOut()
                            }
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.textTitle)
                        }
                    }
                    .padding(.top)

                    // 🏋️ Texto con gimnasio en negrita
                    (
                        Text("Estas son las máquinas disponibles en ")
                        + Text(profile.gym?.name ?? "").fontWeight(.bold)
                    )
                    .font(.body)
                    .foregroundColor(.textBody)

                    // 🛠️ Lista de máquinas
                    if let gym = profile.gym {
                        ForEach(machineVM.machines) { machine in
                            Button {
                                onSelectMachine(machine, gym)
                            } label: {
                                MachineCardView(machine: machine)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .onAppear {
                if let gymId = viewModel.userProfile?.gymId {
                    machineVM.loadMachines(forGymId: gymId)
                }
            }
        }
        .background(Color(hex: "#F5F5F5").ignoresSafeArea())
    }
}

struct MachineCardView: View {
    let machine: Machine

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(machine.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.textTitle)

                    Text(machine.description)
                        .font(.subheadline)
                        .foregroundColor(.textBody)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                AsyncImage(url: URL(string: machine.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        // Mientras carga, mostramos spinner sobre fondo gris claro
                        ZStack {
                            Color(hex:"#CACCD3")
                            ProgressView()
                                .progressViewStyle(
                                    CircularProgressViewStyle(tint: .gray)
                                )
                                .scaleEffect(1.2)
                        }
                    case .success(let image):
                        // Imagen descargada
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        // Si falla, fondo gris con icono de mancuerna
                        ZStack {
                            Color(.systemGray5)
                            Image(systemName: "dumbbell.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.gray.opacity(0.7))
                        }
                    @unknown default:
                        // Para futuros casos
                        ZStack {
                            Color(.systemGray5)
                            ProgressView()
                                .progressViewStyle(
                                    CircularProgressViewStyle(tint: .gray)
                                )
                                .scaleEffect(1.2)
                        }
                    }
                }
                .frame(width: 80, height: 80)
                .clipped()
                .cornerRadius(10)

            }

            HStack {
                Text("Ver tutorial")
                Image(systemName: "arrow.right")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: "#F5F5F0"))
            .foregroundColor(.textTitle)
            .cornerRadius(8)
            .font(.system(size: 14, weight: .semibold))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

/*struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(viewModel: Mock2AuthViewModel())
            .environmentObject(Mock2AuthViewModel())
            .environment(\.colorScheme, .light)
            .previewDevice("iPhone 15")
            .previewDisplayName("HomeView - Gym Machines")
    }
}


class Mock2AuthViewModel: AuthViewModel {
    override init() {
        super.init()
        self.userProfile = UserProfile(
            id: "123",
            name: "Liam",
            phoneNumber: "+51999999999",
            age: 25,
            gender: .masculino,
            gymId: "gym_001",
            gym: Gym(id: "gym_001",
                     address: "Av. Ejemplo 123",
                     color: "#FFD600",
                     name: "Fitness First",
                     owner: "Juan Pérez",
                     phone: "+51999999999",
                     isActive: true),
            weight: 70.0,
            height: 175.0
        )
    }
}

class MockMachineViewModel: MachineViewModel {
    override init() {
        super.init()
        self.machines = [
            Machine(name: "Leg Press", description: "Learn how to use the leg press machine safely and effectively.", defaultVideos: []),
                        Machine(name: "Treadmill", description: "Get started with the treadmill for cardio workouts.", defaultVideos: [])
        ]
    }
}*/

