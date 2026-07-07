import AVFoundation
import Observation

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

    private let bundle: Bundle
    private var players: [AudioCue: AVAudioPlayer] = [:]
    private var currentBGMCue: AudioCue?

    init(bundle: Bundle = .main) {
        self.bundle = bundle
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
        players[currentBGMCue ?? cue]?.stop()
        guard let player = players[cue] else {
            currentBGMCue = nil
            return
        }
        currentBGMCue = cue
        player.numberOfLoops = -1
        player.currentTime = 0
        player.play()
    }

    func stopBGM() {
        players[currentBGMCue ?? .villageTheme]?.stop()
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

    private func loadPlayers() {
        for cue in AudioCue.allCases {
            guard let url = bundle.url(forResource: cue.rawValue, withExtension: "wav", subdirectory: "Assets/Audio"),
                  let player = try? AVAudioPlayer(contentsOf: url)
            else {
                continue
            }
            player.prepareToPlay()
            players[cue] = player
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
