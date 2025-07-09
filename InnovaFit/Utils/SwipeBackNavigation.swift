import SwiftUI

/// A container that hides the navigation bar but keeps the swipe-to-go-back gesture.
struct SwipeBackNavigation<Content: View>: UIViewControllerRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let hosting = UIHostingController(rootView: content)
        let navController = UINavigationController(rootViewController: hosting)
        navController.interactivePopGestureRecognizer?.delegate = context.coordinator
        navController.setNavigationBarHidden(true, animated: false)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        if let hosting = uiViewController.topViewController as? UIHostingController<Content> {
            hosting.rootView = content
        }
        uiViewController.setNavigationBarHidden(true, animated: false)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
