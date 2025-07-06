import Foundation
import FirebaseAuth

/// Estados posibles de autenticación
enum AuthState {
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
    @Published var authState: AuthState = .login
    @Published var gyms: [Gym] = []

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
                    case .failure:
                        self?.authState = .register
                    }
                }
            }
        }
    }

    /// Envía el código OTP al número de teléfono
    func sendOTP() {
        PhoneAuthProvider.provider().verifyPhoneNumber("+51"+phoneNumber, uiDelegate: nil) { [weak self] id, error in
            DispatchQueue.main.async {
                if let id { self?.verificationID = id; self?.authState = .otp }
                else { print("❌ Error OTP: \(error?.localizedDescription ?? "")") }
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
                return
            }

            guard let uid = result?.user.uid else {
                print("❌ UID no encontrado")
                return
            }

            // ✅ Aquí decides a dónde navegar
            repository.fetchUserProfile(uid: uid) { fetchResult in
                DispatchQueue.main.async {
                    switch fetchResult {
                    case .success(let profile):
                        self.userProfile = profile
                        self.authState = .home     // ⬅️ Navega al Home si ya tiene perfil
                    case .failure:
                        self.authState = .register // ⬅️ Solo si no hay perfil creado
                    }
                }
            }
        }
    }


    /// Registra el usuario en Firestore con los datos proporcionados
    func registerUser(
        name: String,
        age: Int,
        gender: Gender,
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
            gym: gym,
            weight: weight,
            height: height
        )
        repository.saveUserProfile(profile) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.userProfile = profile
                    self?.authState = .home
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

    /// Cierra la sesión del usuario actual y vuelve al estado de login
    func signOut() {
        do {
            try Auth.auth().signOut()
            // Restablecer propiedades relevantes
            phoneNumber = ""
            otpCode = ""
            verificationID = nil
            userProfile = nil
            authState = .login
        } catch {
            print("❌ Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
}
