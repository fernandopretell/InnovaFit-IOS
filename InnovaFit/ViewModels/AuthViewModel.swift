import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import UIKit

/// Estados posibles de autenticación
enum AuthState {
    case splash
    case login
    case otp
    case register
    case home
}

/// ViewModel principal para autenticación por teléfono
class AuthViewModel: ObservableObject {
    @Published var phoneNumber: String = ""
    @Published var otpCode: String = ""
    @Published var verificationID: String?
    @Published var userProfile: UserProfile?
    @Published var authState: AuthState = .splash
    @Published var gyms: [Gym] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Google Sign-In
    @Published var pendingGoogleName: String = ""
    private var pendingAuthProvider: String = "phone"

    private let repository = UserRepository()

    init() {
        loadGyms()
        if let uid = Auth.auth().currentUser?.uid {
            repository.fetchUserProfile(uid: uid) { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let profile):
                        self?.userProfile = profile
                        self?.authState = .home
                        self?.saveFcmToken()
                    case .failure:
                        self?.authState = .register
                    }
                }
            }
        } else {
            authState = .login
        }
    }

    /// Envía el código OTP al número de teléfono
    func sendOTP() {
        self.isLoading = true
        self.errorMessage = nil
        pendingAuthProvider = "phone"
        PhoneAuthProvider.provider().verifyPhoneNumber("+51"+phoneNumber, uiDelegate: nil) { [weak self] id, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let id { self?.verificationID = id; self?.authState = .otp }
                else {
                    self?.errorMessage = "Error al enviar código: \(error?.localizedDescription ?? "")"
                    print("❌ Error OTP: \(error?.localizedDescription ?? "")")
                }
            }
        }
    }

    /// Verifica el código ingresado y decide si debe registrar al usuario o ir a la pantalla principal
    func verifyOTP() {
        guard let verificationID = verificationID else { return }

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: otpCode
        )

        Auth.auth().signIn(with: credential) { [weak self] result, error in
            guard let self = self else { return }

            if let error {
                print("❌ Error al verificar OTP: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.errorMessage = "Código incorrecto"
                }
                return
            }

            guard let uid = result?.user.uid else {
                print("❌ UID no encontrado")
                return
            }

            repository.fetchUserProfile(uid: uid) { fetchResult in
                DispatchQueue.main.async {
                    switch fetchResult {
                    case .success(let profile):
                        self.userProfile = profile
                        self.authState = .home
                        self.saveFcmToken()
                    case .failure:
                        self.authState = .register
                    }
                }
            }
        }
    }

    /// Inicia sesión con Google
    func signInWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            print("❌ No se encontró clientID de Firebase")
            errorMessage = "Error de configuración de Google Sign-In"
            return
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            print("❌ No se encontró rootViewController")
            return
        }

        isLoading = true
        errorMessage = nil

        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] result, error in
            guard let self = self else { return }

            if let error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    // No mostrar error si el usuario canceló
                    if (error as NSError).code != GIDSignInError.canceled.rawValue {
                        self.errorMessage = "Error al iniciar sesión con Google: \(error.localizedDescription)"
                    }
                }
                return
            }

            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "No se pudo obtener el token de Google"
                }
                return
            }

            // Capturar nombre de Google
            DispatchQueue.main.async {
                self.pendingGoogleName = user.profile?.name ?? ""
                self.pendingAuthProvider = "google"
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )

            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let self = self else { return }

                if let error {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Error al iniciar sesión: \(error.localizedDescription)"
                    }
                    return
                }

                guard let uid = authResult?.user.uid else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                    return
                }

                self.repository.fetchUserProfile(uid: uid) { fetchResult in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        switch fetchResult {
                        case .success(let profile):
                            self.userProfile = profile
                            self.authState = .home
                            self.saveFcmToken()
                        case .failure:
                            self.authState = .register
                        }
                    }
                }
            }
        }
    }

    /// Registra el usuario en Firestore con los datos proporcionados
    func registerUser(
        name: String,
        age: Int,
        gender: String,
        gym: Gym,
        phone: String,
        weight: Double,
        height: Double
    ) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let profile = UserProfile(
            id: uid,
            name: name,
            phoneNumber: phone,
            age: age,
            gender: gender,
            gymId: gym.id ?? "",
            gym: gym,
            weight: weight,
            height: height,
            authProvider: pendingAuthProvider
        )
        repository.saveUserProfile(profile) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.userProfile = profile
                    self?.authState = .home
                    self?.saveFcmToken()
                case .failure(let error):
                    print("❌ Error al guardar perfil: \(error.localizedDescription)")
                }
            }
        }
    }

    private func loadGyms() {
        repository.fetchGyms { [weak self] result in
            DispatchQueue.main.async {
                if case let .success(gyms) = result { self?.gyms = gyms }
            }
        }
    }

    /// Guarda el token FCM en Firestore a traves del AppDelegate
    private func saveFcmToken() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        appDelegate.refreshAndSaveFcmToken()
    }

    /// Cierra la sesión del usuario actual y vuelve al estado de login
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            phoneNumber = ""
            otpCode = ""
            verificationID = nil
            userProfile = nil
            pendingGoogleName = ""
            pendingAuthProvider = "phone"
            authState = .login
        } catch {
            print("❌ Error al cerrar sesión: \(error.localizedDescription)")
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
