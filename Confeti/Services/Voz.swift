import Foundation
import UIKit
import AVFoundation

@MainActor
final class Voz {
    static let shared = Voz()
    private let sintetizador = AVSpeechSynthesizer()

    private var activa: Bool {
        UserDefaults.standard.object(forKey: Claves.guiaVoz) as? Bool ?? true
    }

    func detener() {
        sintetizador.stopSpeaking(at: .immediate)
    }

    func decir(_ texto: String) {
        detener()
        guard activa else { return }
        let frase = AVSpeechUtterance(string: texto)
        frase.voice = AVSpeechSynthesisVoice(language: "es-MX")
        frase.rate = 0.45
        sintetizador.speak(frase)
    }

    /// Con VoiceOver activo, hablar encima de él confunde al niño: se usa su propio anuncio.
    func anunciar(_ texto: String) {
        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: texto)
        } else {
            decir(texto)
        }
    }
}
