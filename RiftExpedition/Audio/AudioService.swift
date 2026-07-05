import AVFoundation
import Observation

enum AudioCue: String, CaseIterable {
    case click = "ui_click"
    case attack = "attack_hit"
    case skill = "skill_cast"
    case areaBGM = "area_bgm_loop"
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

    init(bundle: Bundle = .main) {
        self.bundle = bundle
        loadPlayers()
    }

    func play(_ cue: AudioCue) {
        guard let player = players[cue] else { return }
        player.currentTime = 0
        player.play()
    }

    func playAreaBGM() {
        guard let player = players[.areaBGM] else { return }
        player.numberOfLoops = -1
        if !player.isPlaying {
            player.play()
        }
    }

    func stopAreaBGM() {
        players[.areaBGM]?.stop()
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
