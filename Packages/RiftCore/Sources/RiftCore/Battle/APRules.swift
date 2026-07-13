public enum APRules {
    public static let movementDistancePerAPStartingValue = 4.0

    public static func movementCost(forDistance distance: Double) -> Int {
        guard distance.isFinite, distance > 0 else { return 0 }
        return max(1, Int((distance / movementDistancePerAPStartingValue).rounded(.up)))
    }
}
