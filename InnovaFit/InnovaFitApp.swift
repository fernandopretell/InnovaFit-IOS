import SwiftUI
import Firebase
import FirebaseFirestore
import SwiftData
import FirebaseCore
import UserNotifications
import FirebaseAuth
import FirebaseMessaging


// MARK: - AppDelegate con soporte para Universal Links + FCM
class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject,
                   UNUserNotificationCenterDelegate, MessagingDelegate {

    @Published var pendingTag: String?
    @Published var didLaunchViaUniversalLink: Bool = false
    @Published var pendingRoutineNotification: RoutineNotificationPayload?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("AppDelegate: aplicacion lanzo")
        print("Launch options: \(launchOptions ?? [:])")
        FirebaseApp.configure()

        // Configurar delegates de notificaciones y FCM
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        // Solicitar permiso de notificaciones push
        requestNotificationPermission()

        if let activities = launchOptions?[.userActivityDictionary] as? [AnyHashable: Any],
           let activity = activities.values.first as? NSUserActivity,
           activity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = activity.webpageURL,
           let tag = extractTag(from: url) {
            print("Universal link detectado al lanzar: \(url.absoluteString)")
            pendingTag = tag
            didLaunchViaUniversalLink = true
        } else {
            didLaunchViaUniversalLink = false
        }

        // Verificar si se lanzó desde una notificación
        if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            handleNotificationPayload(remoteNotification)
        }

        return true
    }

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {

        print("Continue userActivity called with: \(userActivity.activityType) - URL: \(userActivity.webpageURL?.absoluteString ?? "nil")")

        if userActivity.activityType == NSUserActivityTypeBrowsingWeb,
           let url = userActivity.webpageURL,
           let tag = extractTag(from: url) {
            print("AppDelegate recibio tag por Universal Link: \(tag)")
            self.pendingTag = tag
            didLaunchViaUniversalLink = true
            return true
        }

        return false
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Token APNs recibido: \(tokenString)")
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Error al registrar notificaciones remotas: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        if Auth.auth().canHandleNotification(userInfo) {
            print("Notificacion silenciosa manejada por FirebaseAuth")
            completionHandler(.noData)
            return
        }

        print("Notificacion remota recibida: \(userInfo)")
        completionHandler(.newData)
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Notificacion recibida en foreground: mostrarla como banner
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("FCM: Notificacion en foreground: \(userInfo)")
        completionHandler([.banner, .sound, .badge])
    }

    /// Usuario toco la notificacion: navegar a la rutina
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("FCM: Usuario toco notificacion: \(userInfo)")
        handleNotificationPayload(userInfo)
        completionHandler()
    }

    // MARK: - MessagingDelegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        print("FCM: Token recibido: \(token)")
        saveFcmTokenToFirestore(token: token)
    }

    // MARK: - FCM Token Management

    func saveFcmTokenToFirestore(token: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("FCM: No hay usuario autenticado, no se guarda token")
            return
        }
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData(["fcmToken": token]) { error in
            if let error {
                print("FCM: Error al guardar token: \(error.localizedDescription)")
            } else {
                print("FCM: Token guardado para usuario \(uid)")
            }
        }
    }

    /// Obtener y guardar el token FCM actual (llamar despues de autenticacion)
    func refreshAndSaveFcmToken() {
        Messaging.messaging().token { [weak self] token, error in
            if let error {
                print("FCM: Error al obtener token: \(error.localizedDescription)")
                return
            }
            if let token {
                print("FCM: Token actual: \(token)")
                self?.saveFcmTokenToFirestore(token: token)
            }
        }
    }

    // MARK: - Notification Payload Handling

    private func handleNotificationPayload(_ userInfo: [AnyHashable: Any]) {
        let notificationType = userInfo["type"] as? String ?? ""
        let routineId = userInfo["routineId"] as? String ?? ""

        guard notificationType == "new_routine" || notificationType == "routine_updated" else {
            print("FCM: Tipo de notificacion no manejado: \(notificationType)")
            return
        }

        print("FCM: Navegando a rutina - tipo: \(notificationType), routineId: \(routineId)")
        DispatchQueue.main.async {
            self.pendingRoutineNotification = RoutineNotificationPayload(
                type: notificationType,
                routineId: routineId
            )
        }
    }

    // MARK: - Permission Request

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error al solicitar permiso de notificaciones: \(error.localizedDescription)")
            } else {
                print("Permiso de notificaciones: \(granted ? "aceptado" : "denegado")")
            }
        }

        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    // MARK: - Universal Link Helpers

    private func extractTag(from url: URL) -> String? {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            if let item = components.queryItems?.first(where: { $0.name.lowercased() == "tag" }) {
                let tagValue = item.value
                print("extractTag query item result: \(tagValue ?? "nil")")
                return tagValue
            }
            let lastPath = components.path.split(separator: "/").last
            let pathTag = lastPath.map { String($0) }
            print("extractTag path result: \(pathTag ?? "nil")")
            return pathTag
        }
        return nil
    }

}

// MARK: - Notification Payload Model

struct RoutineNotificationPayload: Equatable {
    let type: String   // "new_routine" or "routine_updated"
    let routineId: String
}

// MARK: - InnovaFitApp

@main
struct InnovaFitApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ ShowFeedback.self ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            print("ModelContainer creado correctamente.")
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("Error al crear ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("ContentView aparece por primera vez")
                }
                .onOpenURL { url in
                    print("onOpenURL recibio: \(url.absoluteString)")
                    if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                       let tag = components.queryItems?.first(where: { $0.name.lowercased() == "tag" })?.value {
                        appDelegate.pendingTag = tag
                        appDelegate.didLaunchViaUniversalLink = true
                    }
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    print("onContinueUserActivity recibio: \(activity.webpageURL?.absoluteString ?? "nil")")
                    if let url = activity.webpageURL,
                       let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                       let tag = components.queryItems?.first(where: { $0.name.lowercased() == "tag" })?.value {
                        appDelegate.pendingTag = tag
                        appDelegate.didLaunchViaUniversalLink = true
                    }
                }
                .environmentObject(appDelegate)
        }
        .modelContainer(sharedModelContainer)
    }
}
