import Foundation

/// Cuánta guía ve el niño al trazar.
enum NivelAyuda: Int, CaseIterable {
    case completa = 1
    case puntos
    case inicio
    case ninguna

    var descripcion: String {
        switch self {
        case .completa: return "Guía completa"
        case .puntos: return "Puntos de ayuda"
        case .inicio: return "Sólo el inicio"
        case .ninguna: return "¡Tú solito!"
        }
    }

    var icono: String {
        switch self {
        case .completa: return "hand.point.up.left.fill"
        case .puntos: return "circle.dotted"
        case .inicio: return "smallcircle.filled.circle"
        case .ninguna: return "sparkles"
        }
    }
}

struct Perfil: Identifiable, Codable, Equatable {
    let id: UUID
    var nombre: String
    var estrellas: Int
    var pinataActiva: Int
    /// Mejor resultado (1 a 3 estrellas) por trazo, con la clave de `Trazo.clave`.
    var mejores: [String: Int]
    var niveles: [String: Int]
    var recientes: [String: [Int]]
    /// Letras del nombre que ya domina sin guía.
    var letrasNombre: Set<String>
    var nombreEscrito: Int
    var pinatasRotas: Int

    init(nombre: String, pinata: Int) {
        id = UUID()
        self.nombre = nombre
        estrellas = 0
        pinataActiva = pinata
        mejores = [:]
        niveles = [:]
        recientes = [:]
        letrasNombre = []
        nombreEscrito = 0
        pinatasRotas = 0
    }

    enum CodingKeys: String, CodingKey {
        case id, nombre, estrellas, pinataActiva, mejores, niveles, recientes, letrasNombre, nombreEscrito, pinatasRotas
    }

    /// Lee perfiles guardados por versiones anteriores aunque les falten campos nuevos.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        nombre = try c.decode(String.self, forKey: .nombre)
        estrellas = try c.decodeIfPresent(Int.self, forKey: .estrellas) ?? 0
        pinataActiva = try c.decodeIfPresent(Int.self, forKey: .pinataActiva) ?? Coleccion.pinatas[0].id
        mejores = try c.decodeIfPresent([String: Int].self, forKey: .mejores) ?? [:]
        niveles = try c.decodeIfPresent([String: Int].self, forKey: .niveles) ?? [:]
        recientes = try c.decodeIfPresent([String: [Int]].self, forKey: .recientes) ?? [:]
        letrasNombre = try c.decodeIfPresent(Set<String>.self, forKey: .letrasNombre) ?? []
        nombreEscrito = try c.decodeIfPresent(Int.self, forKey: .nombreEscrito) ?? 0
        pinatasRotas = try c.decodeIfPresent(Int.self, forKey: .pinatasRotas) ?? 0
    }

    func nivel(de clave: String) -> NivelAyuda {
        NivelAyuda(rawValue: niveles[clave] ?? 1) ?? .completa
    }

    func mejor(de clave: String) -> Int {
        mejores[clave] ?? 0
    }

    /// Trazos de la categoría que ya salen con 3 estrellas.
    func dominados(en categoria: Categoria) -> Int {
        categoria.items.filter { mejor(de: $0.clave) == 3 }.count
    }

    /// Guarda el resultado de un trazo y ajusta su nivel de ayuda:
    /// dos intentos seguidos con 3 estrellas quitan ayuda; dos seguidos con 1 estrella la devuelven.
    mutating func registrar(estrellas resultado: Int, en clave: String) {
        mejores[clave] = max(mejores[clave] ?? 0, resultado)

        var ultimos = (recientes[clave] ?? []) + [resultado]
        if ultimos.count > 2 { ultimos.removeFirst(ultimos.count - 2) }

        var nivel = niveles[clave] ?? NivelAyuda.completa.rawValue
        if ultimos.count == 2 && ultimos.allSatisfy({ $0 == 3 }) {
            nivel = min(nivel + 1, NivelAyuda.ninguna.rawValue)
            ultimos = []
        } else if ultimos.count == 2 && ultimos.allSatisfy({ $0 == 1 }) {
            nivel = max(nivel - 1, NivelAyuda.completa.rawValue)
            ultimos = []
        }

        niveles[clave] = nivel
        recientes[clave] = ultimos
    }

    /// Arma una sesión con el trazo elegido y los dos que más práctica necesitan.
    func sesion(empezandoCon elegido: Trazo?, en categoria: Categoria) -> [String] {
        let candidatos = categoria.items
            .filter { $0.clave != elegido?.clave }
            .shuffled()
            .sorted { mejor(de: $0.clave) < mejor(de: $1.clave) }
        let cuantos = elegido == nil ? Valores.trazosPorSesion : Valores.trazosPorSesion - 1
        let resto = candidatos.prefix(cuantos).map(\.clave)
        if let elegido { return [elegido.clave] + resto }
        return Array(resto)
    }
}
