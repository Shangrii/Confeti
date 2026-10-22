import SwiftUI

/// Botón tipo dulce: cápsula con brillo, borde blanco y un canto oscuro abajo que le da volumen.
/// Al presionarlo se hunde. Altura mínima 64 pt.
struct BotonCaramelo: ButtonStyle {
    var color: ColorCaramelo = .morado
    var grande = false

    func makeBody(configuration: Configuration) -> some View {
        Cuerpo(configuration: configuration, color: color, grande: grande)
    }

    private struct Cuerpo: View {
        let configuration: ButtonStyleConfiguration
        let color: ColorCaramelo
        let grande: Bool
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            let presionado = configuration.isPressed
            let base = isEnabled ? color.base : Color.grisDesactivado
            let canto = isEnabled ? color.canto : Color(hex: "48484C")
            let texto = isEnabled ? color.texto : Color.white

            configuration.label
                .font(.system(grande ? .title : .title3, design: .rounded).weight(.heavy))
                .foregroundStyle(texto)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, grande ? 40 : 28)
                .frame(minHeight: grande ? 84 : 64)
                .background {
                    ZStack {
                        Capsule().fill(canto).offset(y: presionado ? 2 : 7)
                        Capsule().fill(base)
                        Capsule()
                            .fill(LinearGradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0)], startPoint: .top, endPoint: .center))
                            .padding(.horizontal, 10)
                            .padding(.top, 4)
                        Capsule().strokeBorder(Color.white.opacity(0.85), lineWidth: 3)
                    }
                }
                .offset(y: presionado ? 5 : 0)
                .animation(.easeOut(duration: 0.08), value: presionado)
                .onChange(of: presionado) { _, ahora in
                    if ahora { Sonidos.shared.reproducir(.pop) }
                }
        }
    }
}

/// Botón redondo blanco para íconos (bocina, ayuda). 64 pt.
struct BotonRedondo: ButtonStyle {
    var color: Color = .morado

    func makeBody(configuration: Configuration) -> some View {
        let presionado = configuration.isPressed
        return configuration.label
            .font(.title2.weight(.bold))
            .foregroundStyle(color)
            .frame(width: 64, height: 64)
            .background {
                ZStack {
                    Circle().fill(color.opacity(0.45)).offset(y: presionado ? 2 : 6)
                    Circle().fill(Color.white)
                    Circle().strokeBorder(color, lineWidth: 4)
                }
            }
            .offset(y: presionado ? 4 : 0)
            .animation(.easeOut(duration: 0.08), value: presionado)
            .onChange(of: presionado) { _, ahora in
                if ahora { Sonidos.shared.reproducir(.pop) }
            }
    }
}

/// Para tarjetas grandes que funcionan como botón: se encogen un poco al tocarlas.
struct BotonTarjeta: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, ahora in
                if ahora { Sonidos.shared.reproducir(.pop) }
            }
    }
}

/// Botón de bocina que repite una instrucción.
struct BotonEscuchar: View {
    let texto: String
    var etiqueta = "Escuchar instrucción"

    var body: some View {
        Button(action: { Voz.shared.decir(texto) }) {
            Image(systemName: "speaker.wave.2.fill")
        }
        .buttonStyle(BotonRedondo())
        .accessibilityLabel(etiqueta)
        .accessibilityHint("Repite en voz alta qué hacer")
    }
}
