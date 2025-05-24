import Foundation
import FirebaseFirestore

struct Machine: Codable {
    let name: String
    let description: String
    let defaultVideos: [Video]
}

