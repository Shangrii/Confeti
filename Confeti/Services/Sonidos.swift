import Foundation
import AVFoundation

enum Sonido: String, CaseIterable {
    case fuera
    case casi
    case bien
    case excelente
    case desbloqueo
    case correcto
    case cuenta
    case golpe
    case romper
    case pop
}

@MainActor
final class Sonidos {
    static let shared = Sonidos()
    private var reproductores: [Sonido: AVAudioPlayer] = [:]

    /// Los sonidos se cargan una sola vez para que suenen sin retraso durante el trazo.
    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        for sonido in Sonido.allCases {
            let url = Bundle.main.url(forResource: sonido.rawValue, withExtension: "wav")
                ?? Bundle.main.url(forResource: sonido.rawValue, withExtension: "wav", subdirectory: "Sonidos")
            guard let url, let reproductor = try? AVAudioPlayer(contentsOf: url) else { continue }
            reproductor.volume = sonido == .pop ? 0.6 : 1
            reproductor.prepareToPlay()
            reproductores[sonido] = reproductor
        }
    }

    func reproducir(_ sonido: Sonido) {
        let activos = UserDefaults.standard.object(forKey: Claves.sonidos) as? Bool ?? true
        guard activos, let reproductor = reproductores[sonido] else { return }
        reproductor.currentTime = 0
        reproductor.play()
    }
}

/// Música de fondo en loop, bajita para que la voz se siga oyendo.
@MainActor
final class Musica {
    static let shared = Musica()
    private var reproductor: AVAudioPlayer?

    private init() {
        let url = Bundle.main.url(forResource: "musica", withExtension: "wav")
            ?? Bundle.main.url(forResource: "musica", withExtension: "wav", subdirectory: "Sonidos")
        guard let url, let reproductor = try? AVAudioPlayer(contentsOf: url) else { return }
        reproductor.numberOfLoops = -1
        reproductor.volume = 0.18
        reproductor.prepareToPlay()
        self.reproductor = reproductor
    }

    /// Prende o apaga la música según el ajuste del adulto.
    func actualizar() {
        let activa = UserDefaults.standard.object(forKey: Claves.musica) as? Bool ?? true
        guard let reproductor else { return }
        if activa && !reproductor.isPlaying {
            reproductor.play()
        } else if !activa && reproductor.isPlaying {
            reproductor.pause()
        }
    }
}
