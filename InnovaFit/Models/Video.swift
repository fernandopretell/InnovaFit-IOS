import Foundation
import FirebaseFirestore

struct Video: Identifiable, Codable {
    var id: String = UUID().uuidString // o usar el id real si viene de Firestore
    let title: String
    let urlVideo: String
    let cover: String
    let musclesWorked: [String: Muscle]
    let segments: [Segment]?
    
    var safeSegments: [Segment] {
            segments ?? []
        }
    
    enum CodingKeys: String, CodingKey {
            case title, urlVideo, cover, musclesWorked, segments
        }
}


