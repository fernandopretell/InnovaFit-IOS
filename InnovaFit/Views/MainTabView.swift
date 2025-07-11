import SwiftUI
import UIKit

struct MainTabView: View {
    @ObservedObject var viewModel: AuthViewModel
    @StateObject private var machineVM = MachineViewModel()
    @State private var selectedTab: Tab = .home
    @State private var showScanner = false
    @State private var animateScanner = false

    enum Tab {
        case home, history
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Group {
                    switch selectedTab {
                    case .home:
                        HomeView(viewModel: viewModel)
                    case .history:
                        MuscleHistoryView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Custom Tab Bar
                HStack(alignment: .bottom) {
                    TabBarItem(
                        label: "Inicio",
                        iconName: "house.fill",
                        isSelected: selectedTab == .home,
                        action: { withAnimation(.spring()) { selectedTab = .home } }
                    )

                    VStack(spacing: 4) {
                        Button {
                            animateScanner = true
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showScanner = true
                                animateScanner = false
                            }
                        } label: {
                            ZStack {
                                /*Circle()
                                 .fill(Color(hex: "#FFD600"))
                                 .frame(width: 64, height: 64)
                                 .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                                 .scaleEffect(animateScanner ? 1.1 : 1.0)
                                 .animation(.spring(response: 0.3, dampingFraction: 0.5), value: animateScanner)
                                 
                                 Image(systemName: "qrcode.viewfinder")
                                 .resizable()
                                 .scaledToFit()
                                 .frame(width: 28, height: 28)
                                 .foregroundColor(.white)*/
                                
                                Image(systemName: "qrcode.viewfinder") // "plus_icon"
                                    .resizable()
                                    .scaledToFit()
                                    .padding()
                                    .frame(width: 60, height: 60)
                                    .foregroundStyle(Color.black)
                                    .background {
                                        Circle()
                                            .fill(Color.accentColor) // custom64B054Color
                                            .shadow(radius: 3)
                                    }
                            }.padding(.top, 9)
                        }

                        Text("Escanear")
                            .font(.footnote)
                            .foregroundColor(Color.black)
                    }

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

                if showScanner {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    SwipeBackNavigation {
                        QRScannerView { scannedCode in
                            print("📦 Código escaneado: \(scannedCode)")
                            //navigationPath.removeLast()
                            if let tag = extractTag(from: scannedCode) {
                                machineVM.loadDataFromTag(tag)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func extractTag(from urlString: String) -> String? {
        if let components = URLComponents(string: urlString) {
            if let item = components.queryItems?.first(where: { $0.name.lowercased() == "tag" }) {
                return item.value
            }
            let lastPath = components.path.split(separator: "/").last
            return lastPath.map { String($0) }
        }
        return nil
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



