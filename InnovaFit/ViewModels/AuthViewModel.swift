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
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] id, error in
            DispatchQueue.main.async {
                if let id { self?.verificationID = id; self?.authState = .otp }
                else { print("❌ Error OTP: \(error?.localizedDescription ?? "")") }
            }
        }
    }

    /// Verifica el código ingresado y decide si debe registrar al usuario o ir a la pantalla principal
    func verifyOTP() {
        guard let verificationID else { return }
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: otpCode)
        Auth.auth().signIn(with: credential) { [weak self] result, error in
            guard let self else { return }
            if let error { print("❌ Error al verificar OTP: \(error.localizedDescription)"); return }
            guard let uid = result?.user.uid else { return }
            repository.fetchUserProfile(uid: uid) { fetchResult in
                DispatchQueue.main.async {
                    switch fetchResult {
                    case .success(let profile):
                        self.userProfile = profile
                        self.authState = .home
                    case .failure:
                        self.authState = .register
                    }
                }
            }
        }
    }

    /// Registra el usuario en Firestore con los datos proporcionados
    func registerUser(name: String, age: Int, gender: Gender, gym: Gym) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let profile = UserProfile(id: uid, name: name, phoneNumber: phoneNumber, age: age, gender: gender, gym: gym)
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
}
