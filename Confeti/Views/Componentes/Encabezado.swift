import SwiftUI

/// Letrero de madera colgado con cuerdas, como los carteles del jardín.
struct LetreroMadera: View {
    let texto: String
    var colgado = true

    var body: some View {
        Text(texto)
            .font(.system(.title, design: .rounded).weight(.black))
            .foregroundStyle(.white)
            .shadow(color: Color(hex: "5A3315"), radius: 0, x: 0, y: 3)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, 34)
            .padding(.vertical, 14)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 18).fill(Color(hex: "5A3315")).offset(y: 6)
                    RoundedRectangle(cornerRadius: 18)
                        .fill(LinearGradient(colors: [Color(hex: "8B5226"), Color(hex: "6B3F1D")], startPoint: .top, endPoint: .bottom))
                    Canvas { context, size in
                        // Vetas de la madera.
                        for i in 1..<4 {
                            let y = size.height * CGFloat(i) / 4
                            var veta = Path()
                            veta.move(to: CGPoint(x: 14, y: y))
                            veta.addQuadCurve(to: CGPoint(x: size.width - 14, y: y + 2), control: CGPoint(x: size.width / 2, y: y + (i % 2 == 0 ? 5 : -5)))
                            context.stroke(veta, with: .color(Color(hex: "5A3315").opacity(0.35)), lineWidth: 2)
                        }
                        // Clavos.
                        for x in [CGFloat(14), size.width - 14] {
                            let clavo = Path(ellipseIn: CGRect(x: x - 5, y: size.height / 2 - 5, width: 10, height: 10))
                            context.fill(clavo, with: .color(Color(hex: "D9C3A3")))
                        }
                    }
                    RoundedRectangle(cornerRadius: 18).strokeBorder(Color(hex: "5A3315"), lineWidth: 4)
                }
            }
            .overlay(alignment: .top) {
                if colgado {
                    HStack {
                        cuerda
                        Spacer()
                        cuerda
                    }
                    .padding(.horizontal, 26)
                    .offset(y: -34)
                }
            }
            .accessibilityAddTraits(.isHeader)
    }

    private var cuerda: some View {
        Capsule()
            .fill(Color(hex: "C9A27A"))
            .frame(width: 5, height: 40)
            .accessibilityHidden(true)
    }
}

/// Encabezado de cada pantalla: botón para regresar, letrero con el título y, a la derecha,
/// lo que la pantalla necesite (por ejemplo, las estrellas del niño).
struct EncabezadoPantalla<Derecha: View>: View {
    @Environment(\.dismiss) private var dismiss

    private let titulo: String
    private let atras: Bool
    private let derecha: Derecha

    init(_ titulo: String, atras: Bool = true, @ViewBuilder derecha: () -> Derecha) {
        self.titulo = titulo
        self.atras = atras
        self.derecha = derecha()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Group {
                if atras {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.backward")
                            .font(.title.weight(.black))
                    }
                    .buttonStyle(BotonRedondo())
                    .accessibilityLabel("Regresar")
                } else {
                    Color.clear.frame(width: 64, height: 64)
                }
            }
            .frame(minWidth: 140, alignment: .leading)

            LetreroMadera(texto: titulo)
                .frame(maxWidth: .infinity)

            derecha
                .frame(minWidth: 140, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.top, FondoFiesta.altoBanderines - 22)
        .padding(.bottom, 8)
    }
}

extension EncabezadoPantalla where Derecha == EmptyView {
    init(_ titulo: String, atras: Bool = true) {
        self.init(titulo, atras: atras) { EmptyView() }
    }
}

/// Contador de estrellas del jugador activo, para la esquina del encabezado.
struct EstrellasJugador: View {
    @Environment(PerfilesStore.self) private var perfiles

    init() {}

    var body: some View {
        InsigniaEstrellas(cantidad: perfiles.activo?.estrellas ?? 0)
    }
}
