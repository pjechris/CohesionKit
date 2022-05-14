import Foundation

public enum StampError: Error {
    /// received stamp is smaller than current stamp
    case tooOld(current: Stamp, received: Stamp)
}
