import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @ObservedObject var viewModel: AuthViewModel
    @StateObject private var machineVM = MachineViewModel()
    @State private var navigationPath: [NavigationRoute] = []

    enum NavigationRoute: Hashable, Codable {
        case qrScanner
        case machine(machine: Machine, gym: Gym)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                            if let gym = profile.gym {
                                ForEach(machineVM.machines) { machine in
                                    NavigationLink(value: NavigationRoute.machine(machine: machine, gym: gym)) {
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

                // 📷 Botón flotante escáner QR
                Button(action: {
                    navigationPath.append(NavigationRoute.qrScanner)
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
            }
            .background(Color.white.ignoresSafeArea())
            .navigationDestination(for: NavigationRoute.self) { route in
                switch route {
                case .qrScanner:
                    SwipeBackNavigation {
                        QRScannerView { scannedCode in
                            print("📦 Código escaneado: \(scannedCode)")
                            //navigationPath.removeLast()
                            if let tag = extractTag(from: scannedCode) {
                                machineVM.loadDataFromTag(tag)
                            }
                        }
                    }

                case .machine(let machine, let gym):
                    SwipeBackNavigation {
                        MachineScreenContent2(machine: machine, gym: gym)
                    }
                }
            }
        }
        .onChange(of: machineVM.hasLoadedTag) { _, newValue in
            if newValue,
               let machine = machineVM.machine,
               let gym = machineVM.gym {
                navigationPath = [.machine(machine: machine, gym: gym)] // reemplaza ruta
                machineVM.hasLoadedTag = false // resetea para futuros escaneos
            }
        }
    }

    private func extractTag(from urlString: String) -> String? {
        if let components = URLComponents(string: urlString) {
            if let item = components.queryItems?.first(where: { $0.name.lowercased() == "tag" }) {
                return item.value
            }
            let lastPath = components.path.split(separator: "/").last
            return lastPath.map { String($0) }
        }
        return nil
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

