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
        print("🚀 AppDelegate: aplicación lanzó")
        FirebaseApp.configure()
        return true
    }
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL,
           let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let tag = components.queryItems?.first(where: { $0.name == "tag" })?.value {
            
            print("📲 AppDelegate recibió tag por Universal Link: \(tag)")
            self.pendingTag = tag
            return true
        }
        
        return false
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
            print("✅ ModelContainer creado correctamente.")
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("❌ Error al crear ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
                .onAppear {
                    print("🌀 ContentView aparece por primera vez")
                }
                .environmentObject(appDelegate) // ✅ inject AppDelegate como EnvironmentObject
        }
        .modelContainer(sharedModelContainer)
    }
}




