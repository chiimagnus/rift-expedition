import AVFoundation
import Observation

protocol AudioPlaying: AnyObject {
    var currentTime: TimeInterval { get set }
    var volume: Float { get set }
    var numberOfLoops: Int { get set }
    var isPlaying: Bool { get }

    @discardableResult func play() -> Bool
    func stop()
    @discardableResult func prepareToPlay() -> Bool
}

extension AVAudioPlayer: AudioPlaying {}

enum AudioCue: String, CaseIterable {
    case uiClick = "ui_click"
    case attackHit = "attack_hit"
    case skillCast = "skill_cast"
    case battleStart = "battle_start"
    case chestOpen = "chest_open"
    case healDrink = "heal_drink"
    case caveDrip = "cave_drip"
    case villageTheme = "village_theme_loop"
    case wildsTheme = "wilds_theme_loop"
    case caveTheme = "cave_theme_loop"
}

@MainActor
@Observable
final class AudioService {
    var masterVolume: Double = 0.75 {
        didSet {
            updateVolumes()
        }
    }
    var isMuted = false {
        didSet {
            updateVolumes()
        }
    }

    private let makePlayer: (URL) throws -> any AudioPlaying
    private let urlForCue: (AudioCue) -> URL?
    private var players: [AudioCue: any AudioPlaying] = [:]
    private var currentBGMCue: AudioCue?

    init(
        bundle: Bundle = .main,
        makePlayer: @escaping (URL) throws -> any AudioPlaying = { try AVAudioPlayer(contentsOf: $0) },
        urlForCue: ((AudioCue) -> URL?)? = nil
    ) {
        self.makePlayer = makePlayer
        self.urlForCue = urlForCue ?? { cue in
            bundle.url(forResource: cue.rawValue, withExtension: "wav", subdirectory: "Assets/Audio")
        }
        loadPlayers()
    }

    func play(_ cue: AudioCue) {
        guard let player = players[cue] else { return }
        player.currentTime = 0
        player.play()
    }

    func playBGM(for areaID: String) {
        let cue = Self.bgmCue(for: areaID)
        guard currentBGMCue != cue else { return }
        if let currentBGMCue {
            players[currentBGMCue]?.stop()
        }
        guard let player = players[cue] else {
            currentBGMCue = nil
            return
        }
        currentBGMCue = cue
        player.numberOfLoops = -1
        player.currentTime = 0
        player.play()
    }

    func playAmbience(for areaID: String) {
        guard let cue = Self.ambienceCue(for: areaID) else { return }
        play(cue)
    }

    func stopBGM() {
        if let currentBGMCue {
            players[currentBGMCue]?.stop()
        }
        currentBGMCue = nil
    }

    static func bgmCue(for areaID: String) -> AudioCue {
        if areaID.hasPrefix("cave_") {
            return .caveTheme
        }
        if areaID.hasPrefix("wilds_") {
            return .wildsTheme
        }
        return .villageTheme
    }

    static func ambienceCue(for areaID: String) -> AudioCue? {
        areaID.hasPrefix("cave_") ? .caveDrip : nil
    }

    private func loadPlayers() {
        for cue in AudioCue.allCases {
            guard let url = urlForCue(cue) else {
                GameLog.assets.warning("Audio cue missing: \(cue.rawValue, privacy: .public).wav")
                continue
            }
            do {
                let player = try makePlayer(url)
                player.prepareToPlay()
                players[cue] = player
            } catch {
                GameLog.assets.error("Audio cue failed to load: \(cue.rawValue, privacy: .public).wav")
                continue
            }
        }
        updateVolumes()
    }

    private func updateVolumes() {
        let volume = isMuted ? 0 : Float(masterVolume)
        for player in players.values {
            player.volume = volume
        }
    }
}
