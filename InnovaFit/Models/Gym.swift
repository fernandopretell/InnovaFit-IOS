import Foundation
import FirebaseFirestore

struct Gym: Codable, Identifiable {
    @DocumentID var id: String?
    let address: String
    let color: String?
    let name: String
    let owner: String
    let phone: String
    let isActive: Bool
    
    var safeColor: String {
            color ?? "#FDD835" // color hexadecimal por defecto
        }
}

