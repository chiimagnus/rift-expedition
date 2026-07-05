import OSLog

enum GameLog {
    private static let subsystem = "com.riftexpedition.game"

    static let config = Logger(subsystem: subsystem, category: "config")
    static let battle = Logger(subsystem: subsystem, category: "battle")
    static let save = Logger(subsystem: subsystem, category: "save")
    static let map = Logger(subsystem: subsystem, category: "map")
    static let assets = Logger(subsystem: subsystem, category: "assets")
}
