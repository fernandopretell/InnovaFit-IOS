import Foundation
import FirebaseFirestore

struct Machine: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let imageUrl: String
    let defaultVideos: [Video]
}

