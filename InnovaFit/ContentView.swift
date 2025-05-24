import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MachineViewModel
    
    init(viewModel: MachineViewModel = MachineViewModel()) {
        self.viewModel = viewModel
        // No llamar aquí loadDataFromTag
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Cargando datos...")
            } else if let gym = viewModel.gym, let machine = viewModel.machine {
                MachineScreenContent(machine: machine, gym: gym)
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
            } else {
                Text("Esperando tag...")
            }
        }
        .onAppear {
            // Aquí se llama a la función para cargar datos
            if viewModel.tag == nil { // para evitar llamadas repetidas
                viewModel.loadDataFromTag("tag_001")
            }
        }
    }
}


