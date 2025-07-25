import SwiftUI
import Firebase
import FirebaseFirestore
import SwiftData
import FirebaseCore
import UserNotifications
import FirebaseAuth


// MARK: - AppDelegate con soporte para Universal Links
class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {

    @Published var pendingTag: String?
    @Published var didLaunchViaUniversalLink: Bool = false
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("🚀 AppDelegate: aplicación lanzó")
        print("🔗 Launch options: \(launchOptions ?? [:])")
        FirebaseApp.configure()
        
        // 🔐 Solicita permiso de notificaciones push
        requestNotificationPermission()
        
        if let activities = launchOptions?[.userActivityDictionary] as? [AnyHashable: Any],
           let activity = activities.values.first as? NSUserActivity,
           activity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = activity.webpageURL,
           let tag = extractTag(from: url) {
            print("📡 Universal link detectado al lanzar: \(url.absoluteString)")
            pendingTag = tag
            didLaunchViaUniversalLink = true
        } else {
            didLaunchViaUniversalLink = false
        }
        return true
    }
    
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        print("➡️ Continue userActivity called with: \(userActivity.activityType) - URL: \(userActivity.webpageURL?.absoluteString ?? "nil")")
        
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL,
           let tag = extractTag(from: url) {
            print("📲 AppDelegate recibió tag por Universal Link: \(tag)")
            self.pendingTag = tag
            didLaunchViaUniversalLink = true
            return true
        }
        
        return false
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📱 Token APNs recibido: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        Auth.auth().setAPNSToken(deviceToken, type: .unknown) // o .prod si estás en producción
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        if Auth.auth().canHandleNotification(userInfo) {
            print("📬 Notificación silenciosa manejada por FirebaseAuth")
            completionHandler(.noData)
            return
        }

        // Aquí podrías manejar otras notificaciones si tuvieras
        print("🔔 Notificación no relacionada a FirebaseAuth: \(userInfo)")
        completionHandler(.newData)
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Error al solicitar permiso de notificaciones: \(error.localizedDescription)")
            } else {
                print("🔔 Permiso de notificaciones: \(granted ? "aceptado" : "denegado")")
            }
        }

        UIApplication.shared.registerForRemoteNotifications()
    }

    func extractTag(from url: URL) -> String? {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            if let item = components.queryItems?.first(where: { $0.name.lowercased() == "tag" }) {
                let tagValue = item.value
                print("🔎 extractTag query item result: \(tagValue ?? "nil")")
                return tagValue
            }
            let lastPath = components.path.split(separator: "/").last
            let pathTag = lastPath.map { String($0) }
            print("🔎 extractTag path result: \(pathTag ?? "nil")")
            return pathTag
        }
        return nil
    }

}

// InnovaFitApp.swift

@main
struct InnovaFitApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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
          ContentView()
            .environmentObject(appDelegate)
            // Captura Universal Links
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
              guard let url = userActivity.webpageURL else { return }
              print("🌐 [SwiftUI] onContinueUserActivity: \(url.absoluteString)")
              if let tag = appDelegate.extractTag(from: url) {
                print("🔎 Tag extraído: \(tag)")
                appDelegate.pendingTag = tag
                appDelegate.didLaunchViaUniversalLink = true
              }
            }
            // Captura cualquier link (incluye UL y schemes)
            .onOpenURL { url in
              print("🔗 [SwiftUI] onOpenURL: \(url.absoluteString)")
              if let tag = appDelegate.extractTag(from: url) {
                appDelegate.pendingTag = tag
                appDelegate.didLaunchViaUniversalLink = true
              }
            }
        }
        .modelContainer(sharedModelContainer)
      }
}




