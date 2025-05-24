import SwiftUI
import Firebase
import FirebaseFirestore
import SwiftData
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}


@main
struct InnovaFitApp: App {

    @StateObject private var viewModel = MachineViewModel()

    init() {
        FirebaseApp.configure()
    }

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
                .onOpenURL { url in
                    if let tag = URLComponents(url: url, resolvingAgainstBaseURL: true)?
                        .queryItems?.first(where: { $0.name == "tag" })?.value {
                        print("🎯 Tag recibido desde URL: \(tag)")
                        viewModel.loadDataFromTag(tag)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

