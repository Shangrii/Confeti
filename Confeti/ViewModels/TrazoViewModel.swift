import SwiftUI
import Observation

struct PuntoTrazado {
    let posicion: CGPoint
    let dentro: Bool
    let numero: Int
}

enum Retroalimentacion {
    case excelente
    case muyBien
    case bienHecho
    case casi

    var texto: String {
        switch self {
        case .excelente: return "¡Excelente!"
        case .muyBien: return "¡Muy bien!"
        case .bienHecho: return "¡Bien hecho!"
        case .casi: return "Casi, va otra vez"
        }
    }

    var icono: String {
        switch self {
        case .excelente: return "star.fill"
        case .muyBien: return "hand.thumbsup.fill"
        case .bienHecho: return "face.smiling"
        case .casi: return "arrow.counterclockwise"
        }
    }

    var sonido: Sonido {
        switch self {
        case .excelente: return .excelente
        case .muyBien, .bienHecho: return .bien
        case .casi: return .casi
        }
    }
}

struct Evaluacion {
    let cobertura: Double
    let precision: Double
    let ordenCorrecto: Bool
    let estrellas: Int
    let retroalimentacion: Retroalimentacion
}

enum AccionLevantar {
    /// No pasó nada: fue un toque o todavía no se ha trazado lo suficiente.
    case nada
    /// Terminó una parte de una letra de varias partes.
    case siguienteParte
    /// Levantó el dedo a la mitad de una parte; puede seguir trazándola.
    case incompleta
    case evaluado(Evaluacion)
}

/// Lógica del trazo: compara los puntos del dedo contra la ruta de la letra y calcula las estrellas.
/// La vista sólo dibuja y reenvía los gestos.
@MainActor
@Observable
final class TrazoViewModel {
    static let puntosObjetivo = 60
    /// Puntos del dedo más juntos que esto no aportan información y sólo hacen trabajar de más al Canvas.
    static let separacionMinima: CGFloat = 3
    /// Menos puntos que esto es un toque, no un trazo.
    static let puntosMinimos = 4

    let trazo: Trazo
    private(set) var rutas: [Path] = []
    private(set) var objetivos: [[CGPoint]] = []
    private(set) var puntos: [PuntoTrazado] = []
    private(set) var resultado: Evaluacion?
    private(set) var parte = 0
    private(set) var areaLetra: CGRect = .zero

    private var tamano: CGSize = .zero
    private var tolerancia: CGFloat = 0
    private var cubiertos: [Set<Int>] = []
    private var puntosDentro = 0
    private var puntosParte = 0
    private var maxIndice = 0
    private var ordenCorrecto = true

    init(trazo: Trazo) {
        self.trazo = trazo
    }

    var estrellas: Int { resultado?.estrellas ?? 0 }
    var haTrazado: Bool { !puntos.isEmpty }
    var totalPartes: Int { objetivos.count }

    /// Porcentaje del trazo que va sobre la línea, para que VoiceOver lo pueda leer.
    var porcentajeDentro: Int {
        guard !puntos.isEmpty else { return 0 }
        return Int(Double(puntosDentro) / Double(puntos.count) * 100)
    }

    /// Dónde empieza la parte que toca trazar, mientras no haya resultado.
    var inicioParte: CGPoint? {
        guard resultado == nil else { return nil }
        return objetivos[safe: parte]?.first
    }

    /// Hacia dónde va la parte que toca trazar, en radianes.
    var anguloParte: Double? {
        guard let actuales = objetivos[safe: parte], actuales.count > 5 else { return nil }
        let a = actuales[0]
        let b = actuales[5]
        return Double(atan2(b.y - a.y, b.x - a.x))
    }

    /// Calcula la letra para el tamaño disponible. Si el tamaño cambia (por ejemplo al rotar el iPad),
    /// el trazo en curso se reinicia porque sus coordenadas ya no corresponden a la letra.
    func configurar(en nuevo: CGSize, toleranciaRelativa: Double) {
        guard nuevo != tamano, nuevo.width > 0, nuevo.height > 0 else { return }
        tamano = nuevo
        let lado = min(nuevo.width, nuevo.height) * 0.80
        let rect = CGRect(x: (nuevo.width - lado) / 2, y: (nuevo.height - lado) / 2, width: lado, height: lado)
        areaLetra = rect
        rutas = trazo.paths(in: rect)

        // Cada parte recibe puntos objetivo según su largo, para que una rayita no pese igual que un arco.
        let largos = trazo.largos
        let total = max(largos.reduce(0, +), 0.0001)
        var nuevos: [[CGPoint]] = []
        for (indice, ruta) in rutas.enumerated() {
            let largo = largos[safe: indice] ?? 0
            let cantidad = max(16, Int((CGFloat(Self.puntosObjetivo) * largo / total).rounded()))
            nuevos.append(ruta.points(count: cantidad))
        }
        objetivos = nuevos
        tolerancia = lado * CGFloat(toleranciaRelativa)
        reiniciar()
    }

    /// Registra un punto del dedo. Devuelve `true` si el dedo acaba de salirse de la línea.
    @discardableResult
    func agregar(_ punto: CGPoint) -> Bool {
        guard resultado == nil, parte < objetivos.count else { return false }
        if let ultimo = puntos.last, distancia(ultimo.posicion, punto) < Self.separacionMinima {
            return false
        }

        let cercanos = objetivosCercanos(a: punto)
        let dentro = !cercanos.isEmpty
        let estabaDentro = puntos.last?.dentro ?? true
        puntos.append(PuntoTrazado(posicion: punto, dentro: dentro, numero: puntos.count))
        puntosParte += 1

        if dentro {
            puntosDentro += 1
            for cercano in cercanos {
                cubiertos[parte].insert(cercano.indice)
            }
            actualizarOrden(con: cercanos)
        }
        return estabaDentro && !dentro
    }

    /// Decide qué pasa al levantar el dedo: nada, pasar a la siguiente parte o evaluar la letra.
    func levantar(en punto: CGPoint, cortes: Cortes) -> AccionLevantar {
        guard resultado == nil, let actuales = objetivos[safe: parte], let fin = actuales.last else { return .nada }
        guard puntosParte >= Self.puntosMinimos else { return .nada }

        if !trazo.esMultiTrazo {
            if let evaluacion = evaluar(con: cortes) { return .evaluado(evaluacion) }
            return .nada
        }

        let coberturaParte = Double(cubiertos[parte].count) / Double(actuales.count)
        let llegoAlFinal = distancia(punto, fin) <= tolerancia * 1.5
        guard llegoAlFinal || coberturaParte >= 0.7 else { return .incompleta }

        if parte == objetivos.count - 1 {
            if let evaluacion = evaluar(con: cortes) { return .evaluado(evaluacion) }
            return .nada
        }
        parte += 1
        maxIndice = 0
        puntosParte = 0
        return .siguienteParte
    }

    /// Si el niño terminó el trazo siempre gana al menos una estrella.
    static func estrellas(cobertura: Double, precision: Double, ordenCorrecto: Bool, cortes: Cortes) -> Int {
        if cobertura > cortes.cobertura3 && precision > cortes.precision3 && ordenCorrecto { return 3 }
        if cobertura > cortes.cobertura2 && precision > cortes.precision2 { return 2 }
        return 1
    }

    func reiniciar() {
        puntos = []
        resultado = nil
        cubiertos = objetivos.map { _ in Set<Int>() }
        puntosDentro = 0
        puntosParte = 0
        parte = 0
        maxIndice = 0
        ordenCorrecto = true
    }

    /// Calcula cobertura, precisión y orden con los contadores que se fueron llenando durante el trazo,
    /// sin volver a recorrer todos los puntos.
    private func evaluar(con cortes: Cortes) -> Evaluacion? {
        let total = objetivos.reduce(0) { $0 + $1.count }
        guard !puntos.isEmpty, total > 0 else { return nil }
        let totalCubiertos = cubiertos.reduce(0) { $0 + $1.count }
        let cobertura = Double(totalCubiertos) / Double(total)
        let precision = Double(puntosDentro) / Double(puntos.count)
        let estrellas = Self.estrellas(cobertura: cobertura, precision: precision, ordenCorrecto: ordenCorrecto, cortes: cortes)

        let retro: Retroalimentacion
        switch estrellas {
        case 3: retro = .excelente
        case 2: retro = .muyBien
        default: retro = cobertura > cortes.cobertura1 ? .bienHecho : .casi
        }

        let evaluacion = Evaluacion(cobertura: cobertura, precision: precision, ordenCorrecto: ordenCorrecto, estrellas: estrellas, retroalimentacion: retro)
        resultado = evaluacion
        return evaluacion
    }

    private func objetivosCercanos(a punto: CGPoint) -> [(indice: Int, distancia: CGFloat)] {
        guard let actuales = objetivos[safe: parte] else { return [] }
        var cercanos: [(indice: Int, distancia: CGFloat)] = []
        for (indice, objetivo) in actuales.enumerated() {
            let d = distancia(punto, objetivo)
            if d <= tolerancia {
                cercanos.append((indice: indice, distancia: d))
            }
        }
        return cercanos
    }

    /// El índice del objetivo alcanzado debe avanzar. Se busca primero cerca del último avance
    /// para que en letras cerradas (O, 0, 8) el final no se confunda con el inicio.
    private func actualizarOrden(con cercanos: [(indice: Int, distancia: CGFloat)]) {
        let enVentana = cercanos.filter { $0.indice >= maxIndice - 5 && $0.indice <= maxIndice + 15 }
        if let mejor = enVentana.min(by: { $0.distancia < $1.distancia }) {
            maxIndice = max(maxIndice, mejor.indice)
        } else if let salto = cercanos.map(\.indice).filter({ $0 > maxIndice + 15 }).min() {
            maxIndice = salto
        } else {
            ordenCorrecto = false
        }
    }
}
