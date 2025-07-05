import Foundation
import FirebaseFirestore

class MachineViewModel: ObservableObject {
    @Published var gym: Gym?
    @Published var machine: Machine?
    @Published var tag: String?
    @Published var machines: [Machine] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoadedTag = false  // ✅ Nueva bandera

    func loadDataFromTag(_ tag: String) {
        self.tag = tag
        self.isLoading = true
        self.errorMessage = nil
        self.hasLoadedTag = false  // ✅ Se reinicia al iniciar

        MachineLoader.resolveTag(tag: tag) { [weak self] gymId, machineId in
            guard let self = self else { return }

            guard let gymId = gymId, let machineId = machineId else {
                DispatchQueue.main.async {
                    self.errorMessage = "No se encontró el tag"
                    self.isLoading = false
                    self.hasLoadedTag = false  // ❌ no cargó
                }
                return
            }

            let group = DispatchGroup()

            var loadedGym: Gym?
            var loadedMachine: Machine?

            group.enter()
            MachineLoader.loadGym(gymId: gymId) { gym in
                loadedGym = gym
                group.leave()
            }

            group.enter()
            MachineLoader.loadMachine(machineId: machineId) { machine in
                loadedMachine = machine
                group.leave()
            }

            group.notify(queue: .main) {
                self.gym = loadedGym
                self.machine = loadedMachine
                self.isLoading = false
                self.hasLoadedTag = loadedGym != nil && loadedMachine != nil  // ✅ sólo true si todo cargó bien
            }
        }
    }

    /// Carga todas las máquinas disponibles para un gimnasio
    func loadMachines(forGymId gymId: String) {
        isLoading = true
        errorMessage = nil
        MachineLoader.loadMachinesForGym(gymId: gymId) { [weak self] machines in
            DispatchQueue.main.async {
                self?.machines = machines
                self?.isLoading = false
            }
        }
    }
}


