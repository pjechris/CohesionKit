import Foundation
import Combine
import CohesionKit

extension URLSessionWebSocketTask {
    func listen(completionHandler: @escaping (Result<Message, Error>) -> Void) {
        receive { [weak self] in
            completionHandler($0)
            self?.listen(completionHandler: completionHandler)
        }
    }
}

class TradeRepository {
    let identityMap = IdentityMap<Date>()
    lazy var webSocketTask: URLSessionWebSocketTask = URLSession
        .shared
        .webSocketTask(with: URL(string: "wss://ws.finnhub.io?token=c2ha9saad3ifd59bkhsg")!)

    func follow(symbol: String) -> AnyPublisher<LastPriceResponse.Trade, Never> {

        let request = LastPriceRequest(type: "subscribe", symbol: symbol)

        webSocketTask.resume()
        webSocketTask.send(.data(try! JSONEncoder().encode(request))) { _ in }
        webSocketTask.listen { [identityMap] result in
            if let message = try? result.get() {
                switch message {
                case .data(let data):
                    let response = try? JSONDecoder().decode(LastPriceResponse.self, from: data)

                    response?.data.forEach {
                        identityMap.updateIfPresent($0, stamp: $0.t)
                    }
                case let .string(json):
                    let response = try? JSONDecoder().decode(LastPriceResponse.self, from: json.data(using: .utf8)!)

                    response?.data.forEach {
                        identityMap.updateIfPresent($0, stamp: $0.t)
                    }
                }
            }
        }

        return identityMap
            .publisher(for: LastPriceResponse.Trade.self, id: symbol)
    }
}
