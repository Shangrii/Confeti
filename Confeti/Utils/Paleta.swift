import SwiftUI

extension Color {
    static let crema = Color(hex: "FFF8EC")
    static let papel = Color(hex: "FFFDF7")
    static let morado = Color(hex: "5B2A86")
    static let moradoOscuro = Color(hex: "3E1A5E")
    static let amarillo = Color(hex: "FFC42E")
    static let amarilloOscuro = Color(hex: "C98F00")
    static let verde = Color(hex: "2E8B57")
    /// Verde para texto y botones: el verde original sólo llega a 4.2:1 con blanco.
    static let verdeTexto = Color(hex: "1E7A47")
    static let rosa = Color(hex: "C2185B")
    static let naranja = Color(hex: "C2410C")
    static let turquesa = Color(hex: "00796B")
    static let azul = Color(hex: "1565C0")
    static let grisDesactivado = Color(hex: "6E6E73")

    static let cieloAlto = Color(hex: "7FD3F7")
    static let pasto = Color(hex: "8BD16A")
    static let pastoOscuro = Color(hex: "5DAE45")

    /// Colores vivos de papel de china para adornos. Nunca llevan texto encima.
    static let fiesta: [Color] = [
        Color(hex: "FF5DA2"), Color(hex: "FF9F1C"), Color(hex: "FFD93D"),
        Color(hex: "6BCB77"), Color(hex: "4D96FF"), Color(hex: "B983FF"),
    ]

    /// Colores oscuros para letras de títulos sobre fondo claro (todos pasan 4.5:1).
    static let titulo: [Color] = [.morado, .rosa, .naranja, .turquesa, .azul, .verdeTexto]

    init(hex: String) {
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

/// Par de colores para los botones tipo dulce: la cara y el canto de abajo que les da volumen.
struct ColorCaramelo {
    let base: Color
    let canto: Color
    let texto: Color

    static let morado = ColorCaramelo(base: .morado, canto: .moradoOscuro, texto: .white)
    static let rosa = ColorCaramelo(base: .rosa, canto: Color(hex: "880E4F"), texto: .white)
    static let naranja = ColorCaramelo(base: .naranja, canto: Color(hex: "7C2D12"), texto: .white)
    static let turquesa = ColorCaramelo(base: .turquesa, canto: Color(hex: "004D40"), texto: .white)
    static let verde = ColorCaramelo(base: .verdeTexto, canto: Color(hex: "0F4A2A"), texto: .white)
    static let azul = ColorCaramelo(base: .azul, canto: Color(hex: "0D3C78"), texto: .white)
    static let amarillo = ColorCaramelo(base: .amarillo, canto: .amarilloOscuro, texto: .moradoOscuro)
    static let blanco = ColorCaramelo(base: .white, canto: Color(hex: "C9B8DA"), texto: .morado)
}
