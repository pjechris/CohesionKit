import Foundation

struct LastPriceRequest: Encodable {
    let type: String
    let symbol: String
}

struct LastPriceResponse: Decodable {
    let data: [Trade]
    let type: String

    struct Trade: Decodable, Identifiable, Hashable {
        var id: String { s }

        let p: Double
        let s: String
        let t: Date
        let v: Double

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func==(lhs: Self, rhs: Self) -> Bool {
            lhs.id == rhs.id
        }
    }
}
