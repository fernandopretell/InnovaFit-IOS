import Foundation
import FirebaseFirestore

class MachineViewModel: ObservableObject {
    @Published var gym: Gym?
    @Published var machine: Machine?
    @Published var tag: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadDataFromTag(_ tag: String) {
        self.tag = tag
        isLoading = true
        errorMessage = nil

        MachineLoader.resolveTag(tag: tag) { [weak self] gymId, machineId in
            guard let self = self else { return }

            guard let gymId = gymId, let machineId = machineId else {
                DispatchQueue.main.async {
                    self.errorMessage = "No se encontró el tag"
                    self.isLoading = false
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
                DispatchQueue.main.async {
                    self.gym = loadedGym
                    self.machine = loadedMachine
                    self.isLoading = false
                }
            }
        }
    }
}

