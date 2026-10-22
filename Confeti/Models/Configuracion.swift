import Foundation

enum Claves {
    static let tolerancia = "tolerancia"
    static let cobertura1 = "cobertura1"
    static let cobertura2 = "cobertura2"
    static let precision2 = "precision2"
    static let cobertura3 = "cobertura3"
    static let precision3 = "precision3"
    static let umbrales = "umbrales"
    static let sonidos = "sonidos"
    static let guiaVoz = "guiaVoz"
    static let musica = "musica"
}

enum Valores {
    static let tolerancia = 0.12
    static let cobertura1 = 0.60
    static let cobertura2 = 0.75
    static let precision2 = 0.70
    static let cobertura3 = 0.90
    static let precision3 = 0.85
    static let umbrales = "15, 30, 50, 75, 105, 140, 180, 225"
    static let trazosPorSesion = 3
    static let rondasPorJuego = 3
    static let letrasNombrePorSesion = 2
    static let golpesPinata = 3
}

/// Cortes de cobertura y precisión que definen cuántas estrellas gana un trazo.
struct Cortes {
    var cobertura1 = Valores.cobertura1
    var cobertura2 = Valores.cobertura2
    var precision2 = Valores.precision2
    var cobertura3 = Valores.cobertura3
    var precision3 = Valores.precision3
}

enum ValidadorUmbrales {
    static let cantidad = 8
    static let rango = 1...999

    /// Devuelve un mensaje que explica qué corregir, o `nil` si el texto es válido.
    static func error(en texto: String) -> String? {
        let partes = texto.split(separator: ",", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard partes.count == cantidad else { return "Escribe \(cantidad) números separados por comas." }
        let numeros = partes.compactMap { Int($0) }
        guard numeros.count == cantidad else { return "Sólo se permiten números enteros." }
        guard numeros.allSatisfy({ rango.contains($0) }) else { return "Cada número debe estar entre 1 y 999." }
        guard zip(numeros, numeros.dropFirst()).allSatisfy({ par in par.0 < par.1 }) else {
            return "Cada número debe ser mayor que el anterior."
        }
        return nil
    }

    static func valores(de texto: String) -> [Int]? {
        guard error(en: texto) == nil else { return nil }
        return texto.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
    }
}
