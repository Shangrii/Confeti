import Foundation

/// Reglas del modo "Mi nombre": cómo se convierte el nombre del niño en las letras que va a practicar.
enum Nombre {
    static let maximoCaracteres = 12

    /// Pasa el texto a letras mayúsculas del abecedario español. Quita acentos y diéresis
    /// (Á → A, Ü → U) pero conserva la Ñ, y descarta los espacios y cualquier otro símbolo.
    static func normalizar(_ texto: String) -> [String] {
        texto.uppercased().compactMap { caracter -> String? in
            if caracter == "Ñ" { return "Ñ" }
            let sinAcento = String(caracter).folding(options: .diacriticInsensitive, locale: Locale(identifier: "es_MX"))
            guard let letra = sinAcento.first, letra.isASCII, letra.isLetter else { return nil }
            return String(letra)
        }
    }

    /// Letras distintas del nombre, en el orden en que aparecen: "Ana" → ["A", "N"].
    static func letras(de texto: String) -> [String] {
        var vistas = Set<String>()
        return normalizar(texto).filter { vistas.insert($0).inserted }
    }

    /// Todas las letras del nombre en orden, con las repetidas: "Ana" → ["A", "N", "A"].
    static func secuencia(de texto: String) -> [String] {
        normalizar(texto)
    }
}

enum ValidadorNombre {
    /// Devuelve un mensaje que explica qué corregir, o `nil` si el nombre es válido.
    static func error(en nombre: String, existentes: [String]) -> String? {
        let limpio = nombre.trimmingCharacters(in: .whitespaces)
        if limpio.isEmpty { return "Escribe un nombre." }
        if limpio.count > Nombre.maximoCaracteres { return "Usa máximo \(Nombre.maximoCaracteres) letras." }
        let sinEspacios = limpio.filter { $0 != " " }
        if Nombre.normalizar(limpio).count != sinEspacios.count { return "Usa sólo letras." }
        if existentes.contains(where: { $0.caseInsensitiveCompare(limpio) == .orderedSame }) {
            return "Ya hay un jugador con ese nombre."
        }
        return nil
    }

    /// Quita espacios de más: "  Ana   María " → "Ana María".
    static func limpiar(_ nombre: String) -> String {
        nombre.split(separator: " ").joined(separator: " ")
    }
}
