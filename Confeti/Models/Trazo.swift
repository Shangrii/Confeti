import SwiftUI

enum Categoria: String, CaseIterable, Identifiable, Hashable {
    case letras
    case numeros

    var id: String { rawValue }
    var titulo: String { self == .letras ? "Letras" : "Números" }
    var muestra: String { self == .letras ? "ABC" : "123" }
    var orden: [String] {
        self == .letras
            ? "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ".map(String.init)
            : "0123456789".map(String.init)
    }

    /// Los trazos de la categoría en orden alfabético o numérico.
    var items: [Trazo] {
        orden.compactMap { id in Trazo.catalogo.first { $0.id == id && $0.categoria == self } }
    }
}

/// Una letra o número. Cada parte (`trazos`) se traza sin levantar el dedo.
/// Los puntos viven en un cuadrado de 0 a 1 (y crece hacia abajo) y se escalan al tamaño de la pantalla.
struct Trazo: Identifiable {
    let id: String
    let categoria: Categoria
    let trazos: [[CGPoint]]

    var clave: String { "\(categoria.rawValue)-\(id)" }
    var esMultiTrazo: Bool { trazos.count > 1 }

    var nombreHablado: String {
        categoria == .letras ? "la letra \(id)" : "el número \(id)"
    }

    func paths(in rect: CGRect) -> [Path] {
        trazos.map { puntos in
            var path = Path()
            path.addLines(puntos.map {
                CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height)
            })
            return path
        }
    }

    /// Largo de cada parte en el cuadrado unitario. Sirve para repartir los puntos objetivo.
    var largos: [CGFloat] {
        trazos.map { puntos in
            zip(puntos, puntos.dropFirst()).reduce(CGFloat(0)) { $0 + distancia($1.0, $1.1) }
        }
    }

    static func letra(_ id: String) -> Trazo? {
        catalogo.first { $0.id == id.uppercased() && $0.categoria == .letras }
    }

    static func numero(_ valor: Int) -> Trazo? {
        catalogo.first { $0.id == String(valor) && $0.categoria == .numeros }
    }

    static func buscar(clave: String) -> Trazo? {
        catalogo.first { $0.clave == clave }
    }
}

extension Trazo {
    init(id: String, categoria: Categoria, puntos: [CGPoint]) {
        self.init(id: id, categoria: categoria, trazos: [puntos])
    }
}

private func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
    CGPoint(x: x, y: y)
}

private func linea(_ a: CGPoint, _ b: CGPoint, pasos: Int = 24) -> [CGPoint] {
    (0...pasos).map { i in
        let t = CGFloat(i) / CGFloat(pasos)
        return CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }
}

private func unir(_ segmentos: [[CGPoint]]) -> [CGPoint] {
    guard var resultado = segmentos.first else { return [] }
    for seg in segmentos.dropFirst() {
        if let primero = seg.first, let ultimo = resultado.last, distancia(primero, ultimo) < 0.001 {
            resultado.append(contentsOf: seg.dropFirst())
        } else {
            resultado.append(contentsOf: seg)
        }
    }
    return resultado
}

/// Ángulos en grados con la convención de pantalla: 0 = derecha, 90 = abajo.
/// Si `hasta` es menor que `desde`, el arco se recorre en sentido antihorario.
private func arco(centro c: CGPoint, rx: CGFloat, ry: CGFloat, desde: CGFloat, hasta: CGFloat, pasos: Int = 48) -> [CGPoint] {
    (0...pasos).map { i in
        let t = CGFloat(i) / CGFloat(pasos)
        let radianes = (desde + (hasta - desde) * t) * .pi / 180
        return CGPoint(x: c.x + rx * cos(radianes), y: c.y + ry * sin(radianes))
    }
}

extension Trazo {
    static let catalogo: [Trazo] = [
        // Letras de un solo trazo
        Trazo(id: "O", categoria: .letras, puntos: arco(centro: p(0.5, 0.5), rx: 0.36, ry: 0.44, desde: -90, hasta: -450, pasos: 90)),
        Trazo(id: "C", categoria: .letras, puntos: arco(centro: p(0.55, 0.5), rx: 0.36, ry: 0.44, desde: -40, hasta: -320, pasos: 80)),
        Trazo(id: "U", categoria: .letras, puntos: unir([linea(p(0.20, 0.08), p(0.20, 0.60)), arco(centro: p(0.50, 0.60), rx: 0.30, ry: 0.32, desde: 180, hasta: 0), linea(p(0.80, 0.60), p(0.80, 0.08))])),
        Trazo(id: "L", categoria: .letras, puntos: unir([linea(p(0.25, 0.08), p(0.25, 0.90)), linea(p(0.25, 0.90), p(0.78, 0.90))])),
        Trazo(id: "V", categoria: .letras, puntos: unir([linea(p(0.16, 0.08), p(0.50, 0.90)), linea(p(0.50, 0.90), p(0.84, 0.08))])),
        Trazo(id: "J", categoria: .letras, puntos: unir([linea(p(0.65, 0.08), p(0.65, 0.65)), arco(centro: p(0.42, 0.65), rx: 0.23, ry: 0.26, desde: 0, hasta: 175)])),
        Trazo(id: "S", categoria: .letras, puntos: unir([arco(centro: p(0.50, 0.29), rx: 0.28, ry: 0.21, desde: -20, hasta: -270), arco(centro: p(0.50, 0.71), rx: 0.28, ry: 0.21, desde: -90, hasta: 160)])),
        Trazo(id: "I", categoria: .letras, puntos: linea(p(0.50, 0.08), p(0.50, 0.92))),
        Trazo(id: "W", categoria: .letras, puntos: unir([linea(p(0.10, 0.08), p(0.30, 0.90)), linea(p(0.30, 0.90), p(0.50, 0.42)), linea(p(0.50, 0.42), p(0.70, 0.90)), linea(p(0.70, 0.90), p(0.90, 0.08))])),
        Trazo(id: "Z", categoria: .letras, puntos: unir([linea(p(0.18, 0.08), p(0.82, 0.08)), linea(p(0.82, 0.08), p(0.18, 0.90)), linea(p(0.18, 0.90), p(0.82, 0.90))])),

        // Letras de varias partes
        Trazo(id: "A", categoria: .letras, trazos: [linea(p(0.48, 0.08), p(0.16, 0.90), pasos: 20), linea(p(0.52, 0.08), p(0.84, 0.90), pasos: 20), linea(p(0.22, 0.56), p(0.78, 0.56), pasos: 18)]),
        Trazo(id: "B", categoria: .letras, trazos: [linea(p(0.24, 0.08), p(0.24, 0.90), pasos: 20), unir([linea(p(0.24, 0.08), p(0.44, 0.08), pasos: 10), arco(centro: p(0.44, 0.29), rx: 0.22, ry: 0.21, desde: -90, hasta: 90, pasos: 30), linea(p(0.44, 0.50), p(0.24, 0.50), pasos: 10), linea(p(0.24, 0.50), p(0.46, 0.50), pasos: 10), arco(centro: p(0.46, 0.70), rx: 0.24, ry: 0.20, desde: -90, hasta: 90, pasos: 30), linea(p(0.46, 0.90), p(0.24, 0.90), pasos: 10)])]),
        Trazo(id: "D", categoria: .letras, trazos: [linea(p(0.24, 0.08), p(0.24, 0.90), pasos: 20), unir([linea(p(0.24, 0.08), p(0.44, 0.08), pasos: 10), arco(centro: p(0.44, 0.49), rx: 0.32, ry: 0.41, desde: -90, hasta: 90, pasos: 40), linea(p(0.44, 0.90), p(0.24, 0.90), pasos: 10)])]),
        Trazo(id: "E", categoria: .letras, trazos: [linea(p(0.24, 0.08), p(0.24, 0.90), pasos: 20), linea(p(0.24, 0.08), p(0.78, 0.08), pasos: 16), linea(p(0.24, 0.49), p(0.70, 0.49), pasos: 16), linea(p(0.24, 0.90), p(0.78, 0.90), pasos: 16)]),
        Trazo(id: "F", categoria: .letras, trazos: [linea(p(0.24, 0.08), p(0.24, 0.90), pasos: 20), linea(p(0.24, 0.08), p(0.78, 0.08), pasos: 16), linea(p(0.24, 0.49), p(0.70, 0.49), pasos: 16)]),
        Trazo(id: "G", categoria: .letras, trazos: [arco(centro: p(0.54, 0.50), rx: 0.34, ry: 0.42, desde: -35, hasta: -330, pasos: 60), unir([linea(p(0.54, 0.52), p(0.84, 0.52), pasos: 14), linea(p(0.84, 0.52), p(0.84, 0.86), pasos: 14)])]),
        Trazo(id: "H", categoria: .letras, trazos: [linea(p(0.22, 0.08), p(0.22, 0.90), pasos: 20), linea(p(0.78, 0.08), p(0.78, 0.90), pasos: 20), linea(p(0.22, 0.49), p(0.78, 0.49), pasos: 18)]),
        Trazo(id: "K", categoria: .letras, trazos: [linea(p(0.22, 0.08), p(0.22, 0.90), pasos: 20), linea(p(0.78, 0.08), p(0.26, 0.50), pasos: 18), linea(p(0.32, 0.46), p(0.80, 0.90), pasos: 18)]),
        Trazo(id: "M", categoria: .letras, trazos: [linea(p(0.16, 0.08), p(0.16, 0.90), pasos: 20), unir([linea(p(0.18, 0.08), p(0.50, 0.62), pasos: 18), linea(p(0.50, 0.62), p(0.82, 0.08), pasos: 18), linea(p(0.82, 0.08), p(0.82, 0.90), pasos: 20)])]),
        Trazo(id: "N", categoria: .letras, trazos: [linea(p(0.22, 0.08), p(0.22, 0.90), pasos: 20), linea(p(0.24, 0.08), p(0.76, 0.90), pasos: 22), linea(p(0.78, 0.08), p(0.78, 0.90), pasos: 20)]),
        Trazo(id: "Ñ", categoria: .letras, trazos: [linea(p(0.22, 0.22), p(0.22, 0.92), pasos: 18), linea(p(0.24, 0.22), p(0.76, 0.92), pasos: 20), linea(p(0.78, 0.22), p(0.78, 0.92), pasos: 18), linea(p(0.28, 0.08), p(0.72, 0.08), pasos: 16)]),
        Trazo(id: "P", categoria: .letras, trazos: [linea(p(0.24, 0.08), p(0.24, 0.90), pasos: 20), unir([linea(p(0.24, 0.08), p(0.46, 0.08), pasos: 10), arco(centro: p(0.46, 0.29), rx: 0.24, ry: 0.21, desde: -90, hasta: 90, pasos: 32), linea(p(0.46, 0.50), p(0.24, 0.50), pasos: 10)])]),
        Trazo(id: "Q", categoria: .letras, trazos: [arco(centro: p(0.50, 0.46), rx: 0.32, ry: 0.38, desde: -90, hasta: -450, pasos: 80), linea(p(0.62, 0.66), p(0.88, 0.92), pasos: 16)]),
        Trazo(id: "R", categoria: .letras, trazos: [linea(p(0.24, 0.08), p(0.24, 0.90), pasos: 20), unir([linea(p(0.24, 0.08), p(0.46, 0.08), pasos: 10), arco(centro: p(0.46, 0.29), rx: 0.24, ry: 0.21, desde: -90, hasta: 90, pasos: 32), linea(p(0.46, 0.50), p(0.24, 0.50), pasos: 10)]), linea(p(0.42, 0.50), p(0.78, 0.90), pasos: 18)]),
        Trazo(id: "T", categoria: .letras, trazos: [linea(p(0.50, 0.08), p(0.50, 0.90), pasos: 20), linea(p(0.18, 0.08), p(0.82, 0.08), pasos: 18)]),
        Trazo(id: "X", categoria: .letras, trazos: [linea(p(0.18, 0.08), p(0.82, 0.90), pasos: 22), linea(p(0.82, 0.08), p(0.18, 0.90), pasos: 22)]),
        Trazo(id: "Y", categoria: .letras, trazos: [linea(p(0.16, 0.08), p(0.50, 0.50), pasos: 16), linea(p(0.84, 0.08), p(0.50, 0.50), pasos: 16), linea(p(0.50, 0.50), p(0.50, 0.90), pasos: 16)]),

        // Números
        Trazo(id: "0", categoria: .numeros, puntos: arco(centro: p(0.5, 0.5), rx: 0.28, ry: 0.44, desde: -90, hasta: -450, pasos: 90)),
        Trazo(id: "1", categoria: .numeros, puntos: unir([linea(p(0.30, 0.28), p(0.55, 0.08)), linea(p(0.55, 0.08), p(0.55, 0.92))])),
        Trazo(id: "2", categoria: .numeros, puntos: unir([arco(centro: p(0.50, 0.30), rx: 0.30, ry: 0.22, desde: 190, hasta: 400), linea(p(0.73, 0.44), p(0.20, 0.92)), linea(p(0.20, 0.92), p(0.82, 0.92))])),
        Trazo(id: "3", categoria: .numeros, puntos: unir([arco(centro: p(0.48, 0.29), rx: 0.28, ry: 0.21, desde: 200, hasta: 450), arco(centro: p(0.48, 0.71), rx: 0.31, ry: 0.21, desde: -90, hasta: 150)])),
        Trazo(id: "4", categoria: .numeros, trazos: [unir([linea(p(0.62, 0.08), p(0.18, 0.62)), linea(p(0.18, 0.62), p(0.84, 0.62))]), linea(p(0.62, 0.08), p(0.62, 0.92))]),
        Trazo(id: "5", categoria: .numeros, puntos: unir([linea(p(0.74, 0.08), p(0.24, 0.08)), linea(p(0.24, 0.08), p(0.24, 0.47)), arco(centro: p(0.45, 0.66), rx: 0.30, ry: 0.26, desde: -135, hasta: 120)])),
        Trazo(id: "6", categoria: .numeros, puntos: unir([linea(p(0.70, 0.08), p(0.46, 0.38)), arco(centro: p(0.46, 0.64), rx: 0.30, ry: 0.26, desde: 270, hasta: 630, pasos: 70)])),
        Trazo(id: "7", categoria: .numeros, puntos: unir([linea(p(0.20, 0.08), p(0.80, 0.08)), linea(p(0.80, 0.08), p(0.42, 0.92))])),
        Trazo(id: "8", categoria: .numeros, puntos: unir([arco(centro: p(0.50, 0.28), rx: 0.22, ry: 0.20, desde: 90, hasta: 450, pasos: 50), arco(centro: p(0.50, 0.70), rx: 0.26, ry: 0.22, desde: -90, hasta: 270, pasos: 50)])),
        Trazo(id: "9", categoria: .numeros, puntos: unir([arco(centro: p(0.48, 0.32), rx: 0.26, ry: 0.22, desde: 30, hasta: 390, pasos: 50), linea(p(0.705, 0.43), p(0.60, 0.95))])),
    ]
}
