import Foundation
import FirebaseFirestore

struct Machine: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    let name: String
    let description: String
    let imageUrl: String
    let defaultVideos: [Video]
}

