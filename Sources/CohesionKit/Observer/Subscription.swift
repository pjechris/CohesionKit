import Foundation

public class Subscription {
    public let unsubscribe: () -> Void

    init(unsubscribe: @escaping () -> Void) {
        var unsubscribed = false

        self.unsubscribe = {
            if !unsubscribed {
                unsubscribe()
            }

            unsubscribed = true
        }
    }

    deinit {
        unsubscribe()
    }
}