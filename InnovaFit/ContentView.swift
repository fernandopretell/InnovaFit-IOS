import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MachineViewModel
    @EnvironmentObject var appDelegate: AppDelegate

    @State private var shouldNavigateToRestricted = false

    var body: some View {
        NavigationStack {
            ZStack {
                Group {
                    if viewModel.isLoading {
                        ProgressView("Cargando datos...")
                    } else if let gym = viewModel.gym, let machine = viewModel.machine {
                        if !gym.isActive {
                            Text("El gimnasio está inactivo")
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding()
                        } else {
                            MachineScreenContent(machine: machine, gym: gym)
                        }
                    } else if viewModel.errorMessage != nil {
                        Text("La máquina aún no está activada")
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    } else {
                        Text("Esperando tag...")
                            .foregroundColor(.gray)
                    }
                }
            }

            .navigationDestination(isPresented: $shouldNavigateToRestricted) {
                AccessRestrictedView {
                    shouldNavigateToRestricted = false
                    exit(0)
                }
            }

            .onReceive(appDelegate.$pendingTag.compactMap { $0 }) { tag in
                print("📥 Tag recibido desde AppDelegate: \(tag)")
                viewModel.loadDataFromTag(tag)
                appDelegate.pendingTag = nil
            }

            .onOpenURL { url in
                if let tag = URLComponents(url: url, resolvingAgainstBaseURL: true)?
                    .queryItems?.first(where: { $0.name == "tag" })?.value {
                    print("📬 Tag recibido desde onOpenURL: \(tag)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        viewModel.loadDataFromTag(tag)
                    }
                }
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                print("🧭 Continue activity \(userActivity)")
                guard let url = userActivity.webpageURL,
                      let tag = URLComponents(url: url, resolvingAgainstBaseURL: true)?
                    .queryItems?.first(where: { $0.name == "tag" })?.value else {
                    return
                }
                
                print("🔗 Tag recibido desde onContinueUserActivity: \(tag)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    viewModel.loadDataFromTag(tag)
                }
            }
            .onAppear {
                let defaults = UserDefaults.standard
                if !defaults.bool(forKey: "hasLaunchedBefore") {
                    defaults.set(true, forKey: "hasLaunchedBefore")
                }

                // Intenta cargar desde el portapapeles si hay un tag válido
                if viewModel.tag == nil,
                   let clipboardTag = UIPasteboard.general.string,
                   clipboardTag.starts(with: "tag_") {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        viewModel.loadDataFromTag(clipboardTag)
                    }
                    return
                }

                // Espera hasta 4 segundos antes de redirigir
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    if viewModel.tag == nil && !viewModel.isLoading {
                        shouldNavigateToRestricted = true
                    }
                }
            }
        }
    }
}









