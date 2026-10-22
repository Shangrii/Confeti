import Foundation

struct PalabraJuego: Identifiable, Hashable {
    let texto: String
    let femenino: Bool

    var id: String { texto }
    var imagen: String { texto.lowercased() }
    var primeraLetra: String { String(texto.prefix(1)).uppercased() }
    var plural: String { texto.lowercased() + "s" }
    /// "un gato", "una manzana".
    var conArticulo: String { (femenino ? "una " : "un ") + texto.lowercased() }
    /// "Cuántos gatos", "Cuántas manzanas".
    var cuantos: String { femenino ? "Cuántas" : "Cuántos" }
    /// "el gato", "la manzana".
    var definido: String { (femenino ? "la " : "el ") + texto.lowercased() }
}

enum ColeccionPalabras {
    static let catalogo: [PalabraJuego] = [
        PalabraJuego(texto: "Gato", femenino: false),
        PalabraJuego(texto: "Perro", femenino: false),
        PalabraJuego(texto: "Libro", femenino: false),
        PalabraJuego(texto: "Auto", femenino: false),
        PalabraJuego(texto: "Manzana", femenino: true),
        PalabraJuego(texto: "Taco", femenino: false),
        PalabraJuego(texto: "Hotdog", femenino: false),
        PalabraJuego(texto: "Pizza", femenino: true),
        PalabraJuego(texto: "Galleta", femenino: true),
    ]
}
