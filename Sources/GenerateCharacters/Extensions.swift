import Foundation

extension ClosedRange {
    var single: Bool { lowerBound == upperBound }
}
