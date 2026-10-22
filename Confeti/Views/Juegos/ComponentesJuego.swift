import SwiftUI

/// Encabezado común de los juegos: bocina, pregunta y en qué ronda va.
struct EncabezadoJuego: View {
    let pregunta: String
    let ronda: Int
    let total: Int

    var body: some View {
        HStack(spacing: 16) {
            BotonEscuchar(texto: pregunta, etiqueta: "Escuchar la pregunta")
            Text(pregunta)
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.morado)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .calcomania()
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if total > 0 {
                PuntosRonda(actual: ronda, total: total)
            }
        }
    }
}

/// Barra inferior de los juegos: estrellas de la ronda y botón para seguir.
/// Sólo aparece cuando el niño ya acertó; la app nunca avanza sola.
struct PieJuego: View {
    let estrellas: Int
    let esUltima: Bool
    let siguiente: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            FilaEstrellas(cantidad: estrellas, tamano: .largeTitle)
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.white))
                .overlay(Capsule().strokeBorder(Color.morado, lineWidth: 3))
            Spacer()
            Button(action: siguiente) {
                Label(esUltima ? "Terminar" : "Siguiente", systemImage: "arrow.right")
            }
            .buttonStyle(BotonCaramelo(color: .morado))
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

/// Estrellas de una ronda de juego: 3 a la primera, 2 a la segunda, 1 después. Nunca cero.
func estrellasPorErrores(_ errores: Int) -> Int {
    max(3 - errores, 1)
}
