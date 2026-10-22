import SwiftUI

/// Tarjeta grande de menú: color sólido con flecos de piñata arriba, ilustración y título.
struct TarjetaJuego<Ilustracion: View>: View {
    let titulo: String
    let subtitulo: String
    let color: ColorCaramelo
    let accion: () -> Void
    let ilustracion: Ilustracion

    init(titulo: String, subtitulo: String, color: ColorCaramelo, accion: @escaping () -> Void, @ViewBuilder ilustracion: () -> Ilustracion) {
        self.titulo = titulo
        self.subtitulo = subtitulo
        self.color = color
        self.accion = accion
        self.ilustracion = ilustracion()
    }

    var body: some View {
        Button(action: accion) {
            VStack(spacing: 12) {
                ilustracion
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Text(titulo)
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                Text(subtitulo)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 20)
            .padding(.top, 48)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 36).fill(color.canto).offset(y: 10)
                    RoundedRectangle(cornerRadius: 36).fill(color.base)
                    FlecosPinata(colores: [Color.white.opacity(0.35), Color.white.opacity(0.2), Color.white.opacity(0.1)])
                        .frame(height: 36)
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 36, topTrailingRadius: 36))
                    RoundedRectangle(cornerRadius: 36).strokeBorder(Color.white, lineWidth: 5)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 36))
        }
        .buttonStyle(BotonTarjeta())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(titulo)
        .accessibilityHint(subtitulo)
        .accessibilityAddTraits(.isButton)
    }
}

/// Círculo blanco con algo grande adentro: texto, símbolo o imagen. Ilustración de las tarjetas.
struct MedallonBlanco<Contenido: View>: View {
    let contenido: Contenido

    init(@ViewBuilder contenido: () -> Contenido) {
        self.contenido = contenido()
    }

    var body: some View {
        GeometryReader { geo in
            let lado = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(Color.white)
                Circle().strokeBorder(Color.white.opacity(0.6), lineWidth: 8).padding(-8)
                contenido
                    .frame(width: lado * 0.72, height: lado * 0.72)
            }
            .frame(width: lado, height: lado)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .accessibilityHidden(true)
    }
}

enum EstadoFichaLetra {
    case pendiente
    case actual
    case hecha
}

/// Ficha cuadrada con una letra, para mostrar el avance de un nombre o una palabra.
struct FichaLetra: View {
    let letra: String
    let estado: EstadoFichaLetra

    var body: some View {
        VStack(spacing: 2) {
            Text(letra)
                .font(.system(.title, design: .rounded).weight(.heavy))
                .foregroundStyle(estado == .actual ? Color.moradoOscuro : Color.morado)
            Image(systemName: icono)
                .font(.caption.weight(.bold))
                .foregroundStyle(estado == .hecha ? Color.verdeTexto : Color.morado)
        }
        .frame(width: 60, height: 70)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(colorBorde.opacity(0.4)).offset(y: 4)
                RoundedRectangle(cornerRadius: 16).fill(colorFondo)
                RoundedRectangle(cornerRadius: 16).strokeBorder(colorBorde, lineWidth: estado == .actual ? 4 : 2.5)
            }
        }
        .scaleEffect(estado == .actual ? 1.1 : 1)
        .animation(.spring(response: 0.3), value: estado)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Letra \(letra)")
        .accessibilityValue(valorAccesibilidad)
    }

    private var colorFondo: Color {
        switch estado {
        case .actual: return .amarillo
        case .hecha: return Color(hex: "DDF5E4")
        case .pendiente: return .white
        }
    }

    private var colorBorde: Color {
        switch estado {
        case .actual: return .morado
        case .hecha: return .verdeTexto
        case .pendiente: return Color.morado.opacity(0.45)
        }
    }

    private var icono: String {
        switch estado {
        case .hecha: return "checkmark.circle.fill"
        case .actual: return "pencil.circle.fill"
        case .pendiente: return "circle"
        }
    }

    private var valorAccesibilidad: String {
        switch estado {
        case .hecha: return "Lista"
        case .actual: return "Ahora"
        case .pendiente: return "Pendiente"
        }
    }
}

/// Fila de fichas que se puede desplazar si el nombre es largo.
struct FilaFichas: View {
    let letras: [String]
    let estado: (Int) -> EstadoFichaLetra

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(letras.enumerated()), id: \.offset) { indice, letra in
                    FichaLetra(letra: letra, estado: estado(indice))
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
        }
    }
}

/// Puntitos que dicen en qué ronda va el juego.
struct PuntosRonda: View {
    let actual: Int
    let total: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < actual ? Color.amarillo : (i == actual ? Color.white : Color.white.opacity(0.5)))
                    .frame(width: 18, height: 18)
                    .overlay(Circle().strokeBorder(Color.morado, lineWidth: i == actual ? 4 : 2))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Capsule().fill(Color.morado.opacity(0.85)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Ronda \(min(actual + 1, total)) de \(total)")
    }
}

/// Burbuja de mensaje con ícono, como un globo de diálogo.
struct GloboMensaje: View {
    let texto: String
    let icono: String
    var color: Color = .morado

    var body: some View {
        Label(texto, systemImage: icono)
            .font(.system(.title2, design: .rounded).weight(.heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background {
                ZStack {
                    Capsule().fill(color.opacity(0.3)).offset(y: 5)
                    Capsule().fill(Color.white)
                    Capsule().strokeBorder(color, lineWidth: 3)
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }
}
