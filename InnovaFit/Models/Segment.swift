import Foundation

struct Segment: Codable, Identifiable {
    var id: String = UUID().uuidString  // id generado automáticamente en memoria
    let start: Int
    let end: Int
    let tip: String

    enum CodingKeys: String, CodingKey {
        case start, end, tip
    }

    // init estándar para decodificar JSON sin 'id'
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        start = try container.decode(Int.self, forKey: .start)
        end = try container.decode(Int.self, forKey: .end)
        tip = try container.decode(String.self, forKey: .tip)
        // Genera el id en memoria al decodificar
        id = UUID().uuidString
    }
    
    // init manual para crear Segment
    init(start: Int, end: Int, tip: String) {
        self.start = start
        self.end = end
        self.tip = tip
        self.id = UUID().uuidString
    }
}

