import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: MachineViewModel
    @EnvironmentObject var appDelegate: AppDelegate

    @State private var showAccessSheet = false

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
        }

        // ✅ Recibe el tag desde AppDelegate (cuando app se abre con link)
        .onReceive(appDelegate.$pendingTag.compactMap { $0 }) { tag in
            print("📥 Tag recibido desde AppDelegate: \(tag)\n")
            viewModel.loadDataFromTag(tag)
            appDelegate.pendingTag = nil
        }

        // ✅ También maneja cuando la app ya estaba abierta
        .onOpenURL { url in
            
            if let tag = URLComponents(url: url, resolvingAgainstBaseURL: true)?
                .queryItems?.first(where: { $0.name == "tag" })?.value {
                print("📬 Tag recibido desde onOpenURL: \(tag)\n")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("✅ Ejecutando loadDataFromTag con: \(tag)")
                    viewModel.loadDataFromTag(tag)
                }

            }
        }

        // ✅ Aparece la vista
        .onAppear {
            print("🌀 onAppear ejecutado")
            
            let defaults = UserDefaults.standard
            let hasLaunchedBefore = defaults.bool(forKey: "hasLaunchedBefore")
            
            if !hasLaunchedBefore {
                defaults.set(true, forKey: "hasLaunchedBefore")
            }
            
            // Siempre permitimos leer desde portapapeles si no hay tag
            if viewModel.tag == nil,
               let clipboardTag = UIPasteboard.general.string,
               clipboardTag.starts(with: "tag_") {
                print("📋 Tag desde clipboard: \(clipboardTag)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("✅ Ejecutando loadDataFromTag con: \(clipboardTag)")
                    viewModel.loadDataFromTag(clipboardTag)
                }
                return
            }
            
            // ⏱️ Si después de 1 segundo aún no hay tag, mostrar sheet
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if viewModel.tag == nil {
                    print("⛔ No se recibió tag → mostrando AccessRestrictedSheet")
                    showAccessSheet = true
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
    }
}








