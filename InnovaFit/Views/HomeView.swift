import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @ObservedObject var viewModel: AuthViewModel
    @StateObject private var machineVM = MachineViewModel()
    @State private var isPresentingScanner = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let profile = viewModel.userProfile {
                        Text("Hola, \(profile.name) 👋")
                            .font(.title2.bold())
                            .foregroundColor(.textTitle)
                            .padding(.top)

                        Text("Estas son las máquinas disponibles en \(profile.gym.name):")
                            .font(.body)
                            .foregroundColor(.textBody)

                        ForEach(machineVM.machines) { machine in
                            MachineCardView(machine: machine) {
                                print("📹 Ver tutorial para: \(machine.name)")
                                // Puedes navegar al detalle aquí
                            }
                        }

                        Button("Cerrar sesión") {
                            viewModel.signOut()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#00C2FF"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
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

            Button(action: {
                isPresentingScanner = true
            }) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 24, weight: .bold))
                    .padding()
                    .background(Color.innovaYellow)
                    .foregroundColor(.black)
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            .padding()
            .fullScreenCover(isPresented: $isPresentingScanner) {
                QRScannerView { scannedCode in
                    print("📦 Código escaneado: \(scannedCode)")
                    isPresentingScanner = false
                }
            }
        }
        .background(Color.backgroundFields.ignoresSafeArea())
    }
}

struct MachineCardView: View {
    let machine: Machine
    let onTutorialTap: () -> Void

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
                        .lineLimit(2)
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

            Button("Ver tutorial") {
                onTutorialTap()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.innovaYellow)
            .foregroundColor(.black)
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

