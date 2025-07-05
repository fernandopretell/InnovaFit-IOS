import SwiftUI

/// Vista principal tras autenticación
struct HomeView: View {
    @ObservedObject var viewModel: AuthViewModel
    @StateObject private var machineVM = MachineViewModel()

    var body: some View {
        VStack(alignment: .leading) {
            if let profile = viewModel.userProfile {
                Text("Hola, \(profile.name)")
                    .font(.title)
                    .foregroundColor(Color(hex: "#111111"))
                    .padding(.horizontal)
                    .padding(.top)

                List(machineVM.machines.indices, id: \.self) { index in
                    Text(machineVM.machines[index].name)
                }
                .listStyle(PlainListStyle())
                .onAppear {
                    if let gymId = profile.gym.id {
                        machineVM.loadMachines(forGymId: gymId)
                    }
                }
            }
        }
        .background(Color.white)
    }
}
