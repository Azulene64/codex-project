import Foundation

public struct ZoomConverter {
    public let k: Double
    public let deadzone: Double
    public let clampRange: ClosedRange<Int>

    public init(k: Double = 12, deadzone: Double = 0.02, clampRange: ClosedRange<Int> = -4...4) {
        self.k = k
        self.deadzone = deadzone
        self.clampRange = clampRange
    }

    public func steps(fromScale scale: Double) -> Int? {
        guard scale > 0 else { return nil }
        let lnValue = log(scale)
        guard abs(lnValue) >= deadzone else { return nil }

        let raw = Int((k * lnValue).rounded())
        return min(max(raw, clampRange.lowerBound), clampRange.upperBound)
    }
}
