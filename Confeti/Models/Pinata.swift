import Foundation

struct Pinata: Identifiable {
    let id: Int
    let nombre: String
    var imagen: String { "pinata\(id)" }
}

enum Coleccion {
    /// Ilustraciones de Finn Protoyeen. El orden define cuáles se desbloquean primero.
    static let pinatas: [Pinata] = [
        Pinata(id: 5, nombre: "Burrito"),
        Pinata(id: 9, nombre: "Zorro"),
        Pinata(id: 2, nombre: "Caimán"),
        Pinata(id: 1, nombre: "Tejón"),
        Pinata(id: 4, nombre: "Oso"),
        Pinata(id: 6, nombre: "Perrito"),
        Pinata(id: 10, nombre: "Cerdito"),
        Pinata(id: 8, nombre: "Llama"),
        Pinata(id: 7, nombre: "Jabalí"),
        Pinata(id: 3, nombre: "Tucán"),
        Pinata(id: 11, nombre: "Gusanito"),
    ]

    static let iniciales = Array(pinatas.prefix(3))
    static let umbralesIniciales = [15, 30, 50, 75, 105, 140, 180, 225]

    static func umbrales(desde texto: String) -> [Int] {
        ValidadorUmbrales.valores(de: texto) ?? umbralesIniciales
    }

    /// Las primeras 3 piñatas están disponibles desde el inicio.
    static func estrellasNecesarias(indice: Int, umbrales: [Int]) -> Int {
        indice < 3 ? 0 : umbrales[indice - 3]
    }

    static func pinata(id: Int) -> Pinata {
        pinatas.first { $0.id == id } ?? pinatas[0]
    }

    static func desbloqueadas(con estrellas: Int, umbrales: [Int]) -> Int {
        pinatas.indices.filter { estrellasNecesarias(indice: $0, umbrales: umbrales) <= estrellas }.count
    }

    /// La siguiente piñata por ganar, qué tan cerca está (0 a 1) y cuántas estrellas faltan.
    static func siguiente(con estrellas: Int, umbrales: [Int]) -> (pinata: Pinata, avance: Double, faltan: Int)? {
        guard let i = pinatas.indices.first(where: { estrellasNecesarias(indice: $0, umbrales: umbrales) > estrellas }) else {
            return nil
        }
        let meta = estrellasNecesarias(indice: i, umbrales: umbrales)
        let base = estrellasNecesarias(indice: i - 1, umbrales: umbrales)
        let avance = Double(estrellas - base) / Double(max(meta - base, 1))
        return (pinata: pinatas[i], avance: min(max(avance, 0), 1), faltan: meta - estrellas)
    }

    /// La piñata que se ganó al pasar de `antes` a `despues` estrellas, si hubo alguna.
    static func nueva(antes: Int, despues: Int, umbrales: [Int]) -> Pinata? {
        let indice = pinatas.indices.last { i in
            let necesarias = estrellasNecesarias(indice: i, umbrales: umbrales)
            return necesarias > antes && necesarias <= despues
        }
        return indice.map { pinatas[$0] }
    }
}
