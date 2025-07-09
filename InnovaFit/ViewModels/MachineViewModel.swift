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
    
    private let repository = MachineRepository()
    

    func loadDataFromTag(_ tag: String) {
        self.tag = tag
        self.isLoading = true
        self.errorMessage = nil
        self.hasLoadedTag = false  // ✅ Se reinicia al iniciar

        MachineRepository.resolveTag(tag: tag) { [weak self] gymId, machineId in
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
            MachineRepository.loadGym(gymId: gymId) { gym in
                loadedGym = gym
                group.leave()
            }

            group.enter()
            MachineRepository.loadMachine(machineId: machineId) { machine in
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
    /// Carga todas las máquinas disponibles para un gimnasio
    func loadMachines(forGymId gymId: String) {
        // ✅ Previene recarga si ya hay datos
        if !machines.isEmpty {
            print("⏸️ Máquinas ya cargadas, no se vuelve a consultar.")
            return
        }

        isLoading = true
        errorMessage = nil

        print("📥 Iniciando consulta de gym_machines para gymId: \(gymId)")

        MachineRepository.fetchMachinesByGym(forGymId: gymId) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let machines):
                    self?.machines = machines
                case .failure(let error):
                    self?.machines = []
                    self?.errorMessage = error.localizedDescription
                }
            }
        }
    }


}


