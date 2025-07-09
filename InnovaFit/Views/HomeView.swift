import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @ObservedObject var viewModel: AuthViewModel
    @StateObject private var machineVM = MachineViewModel()
    @State private var isPresentingScanner = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
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
                            ForEach(machineVM.machines) { machine in
                                NavigationLink(value: machine) {
                                    MachineCardView(machine: machine)
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

                // 📷 Botón flotante escáner QR
                Button(action: {
                    isPresentingScanner = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "qrcode.viewfinder")
                        Text("Escanea una máquina")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding()
                    .background(Color.innovaYellow)
                    .foregroundColor(.black)
                    .cornerRadius(28)
                }
                .padding()

                NavigationLink(isActive: $isPresentingScanner) {
                    QRScannerView { scannedCode in
                        print("📦 Código escaneado: \(scannedCode)")
                        isPresentingScanner = false
                    }
                    .navigationTitle("Escanear QR")
                    .navigationBarTitleDisplayMode(.inline)
                } label: {
                    EmptyView()
                }
            }
            .background(Color.white.ignoresSafeArea())
            .navigationDestination(for: Machine.self) { machine in
                if let gym = viewModel.userProfile?.gym {
                    MachineScreenContent(machine: machine, gym: gym)
                }
            }
        }
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
                        .foregroundColor(.textTitle)

                    Text(machine.description)
                        .font(.subheadline)
                        .foregroundColor(.textBody)
                        .lineLimit(3)
                }

                Spacer()

                AsyncImage(url: URL(string: machine.imageUrl)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.gray.opacity(0.2)
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
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
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

