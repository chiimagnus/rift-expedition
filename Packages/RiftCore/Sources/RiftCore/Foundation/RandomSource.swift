public protocol RandomSource: Sendable {
    mutating func nextUInt64() -> UInt64
}

public extension RandomSource {
    mutating func nextUnitDouble() -> Double {
        let value = nextUInt64() >> 11
        return Double(value) / Double(1 << 53)
    }

    mutating func roll(chancePercent: Int) -> Bool {
        let clamped = min(max(chancePercent, 0), 100)
        return nextUnitDouble() < Double(clamped) / 100
    }
}
