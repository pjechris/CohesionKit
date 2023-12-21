import Foundation

/// A type used to annotate track object modifications through time.
/// Most of the time you'll just use date as stamp using `Date().stamp` method
public typealias Stamp = Double

extension Date {
    /// Generate a stamp suitable to use in `EntityStore`.
    /// Don't suppose it equals unix timestamp (it is not)
    public var stamp: Stamp {
        timeIntervalSinceReferenceDate
    }
}
