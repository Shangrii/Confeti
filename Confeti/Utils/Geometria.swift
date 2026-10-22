import SwiftUI

extension Path {
    /// Devuelve `count` puntos repartidos a lo largo de la ruta, del inicio al final.
    func points(count: Int) -> [CGPoint] {
        guard count > 1 else { return [] }
        return (0..<count).compactMap { i in
            let fraction = max(CGFloat(i) / CGFloat(count - 1), 0.0001)
            return trimmedPath(from: 0, to: fraction).currentPoint
        }
    }
}

func distancia(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    hypot(a.x - b.x, a.y - b.y)
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
