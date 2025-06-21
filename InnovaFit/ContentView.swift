import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MachineViewModel
    @EnvironmentObject var appDelegate: AppDelegate

    @State private var showAccessSheet = false
    @State private var debugText = ""
    @State private var showDebug = false

    var body: some View {
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

            // 🛠 Overlay de depuración
            DebugOverlay(debugText: debugText, isVisible: $showDebug)
        }

        // ✅ Recibe el tag desde AppDelegate (cuando app se abre con link)
        .onReceive(appDelegate.$pendingTag.compactMap { $0 }) { tag in
            debugText.append("📥 Tag recibido desde AppDelegate: \(tag)\n")
            viewModel.loadDataFromTag(tag)
            appDelegate.pendingTag = nil
        }

        // ✅ También maneja cuando la app ya estaba abierta
        .onOpenURL { url in
            if let tag = URLComponents(url: url, resolvingAgainstBaseURL: true)?
                .queryItems?.first(where: { $0.name == "tag" })?.value {
                debugText.append("📬 Tag recibido desde onOpenURL: \(tag)\n")
                viewModel.loadDataFromTag(tag)
            }
        }

        // ✅ Aparece la vista
        .onAppear {
            debugText.append("🌀 onAppear ejecutado\n")

            if viewModel.tag == nil {
                let defaults = UserDefaults.standard
                let hasLaunchedBefore = defaults.bool(forKey: "hasLaunchedBefore")

                if !hasLaunchedBefore {
                    defaults.set(true, forKey: "hasLaunchedBefore")

                    if let clipboardTag = UIPasteboard.general.string,
                       clipboardTag.starts(with: "tag_") {
                        debugText.append("📋 Tag desde clipboard: \(clipboardTag)\n")
                        viewModel.loadDataFromTag(clipboardTag)
                        return
                    }
                }

                // ⏱️ Esperar 1 segundo antes de mostrar AccessRestrictedSheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if viewModel.tag == nil {
                        debugText.append("⛔ No se recibió tag → mostrando AccessRestrictedSheet\n")
                        showAccessSheet = true
                    }
                }
            }
        }

        // 🚪 Sheet de acceso restringido
        .sheet(isPresented: $showAccessSheet) {
            AccessRestrictedSheet {
                showAccessSheet = false
                exit(0)
            }
        }

        // 🔓 Triple tap para ver log
        .simultaneousGesture(
            TapGesture(count: 3).onEnded {
                //#if DEBUG || targetEnvironment(simulator)
                showDebug.toggle()
                //#endif
            }
        )
    }
}








