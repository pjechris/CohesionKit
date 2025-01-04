import Foundation

/// a class executing an execution upon deinit on call to `unsubscribe`. It can be executed only once
public class Subscription {
    public private(set) var unsubscribe: () -> Void

    static var empty: Subscription { Subscription { } }

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

    /// - Returns: a new subscription both subscriptions
    func merging(subscription: Subscription) -> Subscription {
        Subscription { [self] in
            self.unsubscribe()
            subscription.unsubscribe()
        }
    }
}
