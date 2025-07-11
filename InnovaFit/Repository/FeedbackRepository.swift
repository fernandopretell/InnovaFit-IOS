import Foundation
import FirebaseFirestore

class FeedbackRepository {
    static func saveFeedback(
        gymId: String,
        rating: Int,
        answer: String,
        comment: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let db = Firestore.firestore()
        var data: [String: Any] = [
            "answer": answer,
            "comment": comment,
            "gymId": gymId,
            "os": "IOS",
            "rating": rating,
            "timestamp": FieldValue.serverTimestamp()
        ]

        db.collection("feedback").addDocument(data: data) { error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
