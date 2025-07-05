import SwiftUI

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MachineViewModel
    @EnvironmentObject var appDelegate: AppDelegate

    @State private var shouldShowScanner = false

    var body: some View {
        NavigationStack {
            if shouldShowScanner {
                QRScannerView { result in
                    if let url = URL(string: result),
                       let tag = URLComponents(url: url, resolvingAgainstBaseURL: true)?
                            .queryItems?.first(where: { $0.name == "tag" })?.value {
                        print("📸 Tag escaneado: \(tag)")
                        viewModel.loadDataFromTag(tag)
                    }
                }
            } else {
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
            }
        }
        .onAppear {
            let defaults = UserDefaults.standard
            if !defaults.bool(forKey: "hasLaunchedBefore") {
                defaults.set(true, forKey: "hasLaunchedBefore")
            }

            if !appDelegate.didLaunchViaUniversalLink {
                shouldShowScanner = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                if !viewModel.hasLoadedTag && !viewModel.isLoading {
                    shouldShowScanner = true
                }
            }
        }
        .onChange(of: viewModel.hasLoadedTag) { oldValue, newValue in
            if newValue {
                shouldShowScanner = false
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
                shouldShowScanner = false // 🔄 evita mostrar escáner
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
            shouldShowScanner = false // 🔄 evita que se vea el escáner
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.loadDataFromTag(tag)
            }
        }
    }
}











