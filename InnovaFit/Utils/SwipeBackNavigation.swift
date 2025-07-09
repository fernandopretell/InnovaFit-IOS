import SwiftUI

// MARK: - Componente principal
struct SwipeBackNavigation<Content: View>: UIViewControllerRepresentable {
    let content: Content
    var hidesNavigationBar: Bool

    init(hidesNavigationBar: Bool = true, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.hidesNavigationBar = hidesNavigationBar
    }

    func makeUIViewController(context: Context) -> HostingWithSwipeBack<Content> {
        let controller = HostingWithSwipeBack(rootView: content)
        controller.hidesNavigationBar = hidesNavigationBar
        return controller
    }

    func updateUIViewController(_ uiViewController: HostingWithSwipeBack<Content>, context: Context) {
        uiViewController.rootView = content
    }
}

// MARK: - Subclase de UIHostingController para aplicar swipe back y ocultar la barra
class HostingWithSwipeBack<Content: View>: UIHostingController<Content>, UIGestureRecognizerDelegate {
    var hidesNavigationBar: Bool = true

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let nav = navigationController {
            nav.setNavigationBarHidden(hidesNavigationBar, animated: animated)
            nav.interactivePopGestureRecognizer?.delegate = self
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Evita gesto en la raíz del stack
        navigationController?.viewControllers.count ?? 0 > 1
    }
}

