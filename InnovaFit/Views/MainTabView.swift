import SwiftUI

struct MainTabView: View {
    @ObservedObject var viewModel: AuthViewModel
    @EnvironmentObject private var appDelegate: AppDelegate
    @StateObject private var machineVM = MachineViewModel()
    @State private var selectedTab: Tab = .home
    @State private var navigationPath: [TabsRoute] = []
    @State private var showErrorAlert = false

    enum Tab {
        case home, history
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { proxy in
                ZStack(alignment: .bottom) {
                    // Contenido según pestaña seleccionada
                    contentForSelectedTab()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Custom Tab Bar
                    HStack(alignment: .bottom) {
                        TabBarItem(
                            label: "Inicio",
                            iconName: "house.fill",
                            isSelected: selectedTab == .home,
                            action: { withAnimation(.spring()) { selectedTab = .home } }
                        )

                        ScannerTabButton(proxy: proxy)

                        TabBarItem(
                            label: "Historial",
                            iconName: "clock.arrow.circlepath",
                            isSelected: selectedTab == .history,
                            action: { withAnimation(.spring()) { selectedTab = .history } }
                        )
                    }
                    .font(.footnote)
                    .padding(.horizontal, 10)
                    .padding(.bottom, max(0, 8 - proxy.safeAreaInsets.bottom))
                    .background {
                        TabBarShape()
                            .fill(.white)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
                            .ignoresSafeArea()
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .navigationDestination(for: TabsRoute.self) { route in
                switch route {
                case .machine(let machine, let gym):
                    SwipeBackNavigation {
                        MachineScreenContent2(machine: machine, gym: gym)
                    }
                case .qrScanner:
                    SwipeBackNavigation {
                        QRScannerView { scannedCode in
                            if let tag = extractTag(from: scannedCode) {
                                machineVM.loadDataFromTag(tag)
                            }
                        }
                    }
                }
            }
            .onAppear {
                print("🟢 MainTabView onAppear - didLaunchViaUniversalLink: \(appDelegate.didLaunchViaUniversalLink), tag: \(appDelegate.pendingTag ?? "nil")")
                if appDelegate.didLaunchViaUniversalLink,
                   let tag = appDelegate.pendingTag {
                    // Ensure we start from the Home tab
                    selectedTab = .home
                    print("🚀 Cargando datos para tag en onAppear: \(tag)")
                    machineVM.loadDataFromTag(tag)
                    appDelegate.pendingTag = nil
                }
            }
            .onChange(of: appDelegate.pendingTag) { _, newValue in
                print("🔄 pendingTag cambió a: \(newValue ?? "nil")")
                if appDelegate.didLaunchViaUniversalLink,
                   let tag = newValue {
                    // Ensure we start from the Home tab
                    selectedTab = .home
                    print("🚀 Cargando datos para tag desde onChange: \(tag)")
                    machineVM.loadDataFromTag(tag)
                    appDelegate.pendingTag = nil
                }
            }
            .onChange(of: machineVM.hasLoadedTag) { _, newValue in
                print("📦 hasLoadedTag cambió a: \(newValue)")
                if newValue {
                    // Always display the machine from the Home tab
                    selectedTab = .home

                    if let machine = machineVM.machine, let gym = machineVM.gym {
                        print("✅ Navegando a MachineScreenContent2")
                        navigationPath.append(.machine(machine: machine, gym: gym))
                    } else {
                        showErrorAlert = true
                    }

                    appDelegate.didLaunchViaUniversalLink = false
                    machineVM.hasLoadedTag = false
                }
            }
            .alert("No se encontró una máquina activa para este código.", isPresented: $showErrorAlert) {
                Button("Aceptar", role: .cancel) {}
            }
        }
        .environmentObject(viewModel)
    }

    // MARK: - Constructor de vistas por pestaña

    @ViewBuilder
    private func contentForSelectedTab() -> some View {
        switch selectedTab {
        case .home:
            HomeView(
                viewModel: viewModel,
                onSelectMachine: { machine, gym in
                    navigationPath.append(.machine(machine: machine, gym: gym))
                }
            )
        case .history:
            MuscleHistoryView()
        }
    }

    // MARK: - Botón central de escáner

    private func ScannerTabButton(proxy: GeometryProxy) -> some View {
        VStack(spacing: 4) {
            Button {
                navigationPath.append(.qrScanner)
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 64, height: 64)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)

                    Image(systemName: "qrcode.viewfinder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.black)
                }
            }
            .offset(y: scannerYOffset(proxy: proxy))

            Text("Escanear")
                .font(.footnote)
                .foregroundColor(.black)
        }
    }

    private func scannerYOffset(proxy: GeometryProxy) -> CGFloat {
        let isiPhoneWithIsland = proxy.safeAreaInsets.bottom > 20
        return isiPhoneWithIsland ? 4 : -8
    }

    // MARK: - Extracción de tag de URL

    private func extractTag(from urlString: String) -> String? {
        guard let components = URLComponents(string: urlString) else {
            print("🔎 extractTag no pudo crear URLComponents")
            return nil
        }
        if let item = components.queryItems?.first(where: { $0.name.lowercased() == "tag" }) {
            let val = item.value
            print("🔎 extractTag query: \(val ?? "nil")")
            return val
        }
        let pathTag = components.path.split(separator: "/").last.map(String.init)
        print("🔎 extractTag path: \(pathTag ?? "nil")")
        return pathTag
    }
}

struct TabBarItem: View {
    let label: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color.black : .gray)
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

                Text(label)
                    .foregroundColor(isSelected ? Color.black : .gray)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct TabBarShape: Shape {

    // Constants used for the shape
    private enum Constants {
        static let cornerRadius: CGFloat = 20
        static let smallCornerRadius: CGFloat = 15
        static let buttonRadius: CGFloat = 30
        static let buttonPadding: CGFloat = 9
    }

    // Function to define the shape's path
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Move to the starting point at the bottom-left corner
        var x = rect.minX
        var y = rect.maxY
        path.move(to: CGPoint(x: x, y: y))

        // Add the rounded corner on the top-left corner
        x += Constants.cornerRadius
        y = Constants.buttonRadius + Constants.cornerRadius
        path.addArc(
            center: CGPoint(x: x, y: y),
            radius: Constants.cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(270),
            clockwise: false
        )
        // Add a small corner leading to the main half-circle
        x = rect.midX - Constants.buttonRadius - (Constants.buttonPadding / 2) - Constants.smallCornerRadius
        y = Constants.buttonRadius - Constants.smallCornerRadius
        path.addArc(
            center: CGPoint(x: x, y: y),
            radius: Constants.smallCornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(35), // 0
            clockwise: true
        )
        // Add the main half-circle
        x = rect.midX
        y += Constants.smallCornerRadius + Constants.buttonPadding
        path.addArc(
            center: CGPoint(x: x, y: y),
            radius: Constants.buttonRadius + Constants.buttonPadding,
            startAngle: .degrees(215), // 180
            endAngle: .degrees(325), // 0
            clockwise: false
        )
        // Add a trailing small corner
        x += Constants.buttonRadius + (Constants.buttonPadding / 2) + Constants.smallCornerRadius
        y = Constants.buttonRadius - Constants.smallCornerRadius
        path.addArc(
            center: CGPoint(x: x, y: y),
            radius: Constants.smallCornerRadius,
            startAngle: .degrees(145), // 180
            endAngle: .degrees(90),
            clockwise: true
        )
        // Add the rounded corner on the top-right corner
        x = rect.maxX - Constants.cornerRadius
        y = Constants.buttonRadius + Constants.cornerRadius
        path.addArc(
            center: CGPoint(x: x, y: y),
            radius: Constants.cornerRadius,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )
        // Connect the bottom corner
        x = rect.maxX
        y = rect.maxY
        path.addLine(to: CGPoint(x: x, y: y))

        // Close the path to complete the shape
        path.closeSubpath()
        return path
    }
}



