import SwiftUI
import Firebase
import FirebaseFirestore
import SwiftData
import FirebaseCore

// MARK: - AppDelegate con soporte para Universal Links
class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {

    @Published var pendingTag: String?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        guard
            userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL,
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let tag = components.queryItems?.first(where: { $0.name == "tag" })?.value
        else {
            return false
        }

        print("🌐 Universal Link recibido con tag: \(tag)")

        // ✅ Enviar el tag de forma reactiva
        DispatchQueue.main.async {
            self.pendingTag = tag
        }

        return true
    }
}

// InnovaFitApp.swift

@main
struct InnovaFitApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = MachineViewModel()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ ShowFeedback.self ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .environmentObject(appDelegate) // ✅ inject AppDelegate como EnvironmentObject
        }
        .modelContainer(sharedModelContainer)
    }
}



