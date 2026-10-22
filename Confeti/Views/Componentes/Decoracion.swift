import SwiftUI

/// Tira de papel picado: banderitas de colores con figuras recortadas.
struct PapelPicado: View {
    var cantidad = 11

    var body: some View {
        Canvas { context, size in
            var cuerda = Path()
            cuerda.move(to: CGPoint(x: 0, y: 6))
            cuerda.addQuadCurve(to: CGPoint(x: size.width, y: 6), control: CGPoint(x: size.width / 2, y: 22))
            context.stroke(cuerda, with: .color(Color.moradoOscuro.opacity(0.55)), lineWidth: 2.5)

            let ancho = size.width / CGFloat(cantidad)
            for k in 0..<cantidad {
                let x = CGFloat(k) * ancho + ancho * 0.08
                let t = (CGFloat(k) + 0.5) / CGFloat(cantidad)
                let caida = 4 * t * (1 - t) * 16
                let rect = CGRect(x: x, y: 6 + caida, width: ancho * 0.84, height: size.height - 10 - caida)
                var hoja = context
                hoja.translateBy(x: rect.midX, y: rect.minY)
                hoja.rotate(by: .degrees(k % 2 == 0 ? -3 : 3))
                hoja.translateBy(x: -rect.midX, y: -rect.minY)
                hoja.fill(bandera(en: rect), with: .color(Color.fiesta[k % Color.fiesta.count]), style: FillStyle(eoFill: true))
            }
        }
        .accessibilityHidden(true)
    }

    /// Rectángulo con pico abajo y recortes en forma de flor y diamantes.
    private func bandera(en r: CGRect) -> Path {
        var p = Path()
        let picos = 4
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - 10))
        for i in 0..<picos {
            let paso = r.width / CGFloat(picos)
            let derecha = r.maxX - CGFloat(i) * paso
            p.addLine(to: CGPoint(x: derecha - paso / 2, y: r.maxY))
            p.addLine(to: CGPoint(x: derecha - paso, y: r.maxY - 10))
        }
        p.closeSubpath()

        let centro = CGPoint(x: r.midX, y: r.minY + r.height * 0.45)
        let radio = min(r.width, r.height) * 0.12
        for k in 0..<6 {
            let a = Double(k) * .pi / 3
            let c = CGPoint(x: centro.x + cos(a) * radio * 1.4, y: centro.y + sin(a) * radio * 1.4)
            p.addEllipse(in: CGRect(x: c.x - radio * 0.6, y: c.y - radio * 0.6, width: radio * 1.2, height: radio * 1.2))
        }
        p.addEllipse(in: CGRect(x: centro.x - radio * 0.7, y: centro.y - radio * 0.7, width: radio * 1.4, height: radio * 1.4))
        for dx in [-0.3, 0.3] {
            let d = CGPoint(x: r.midX + r.width * CGFloat(dx), y: r.minY + r.height * 0.14)
            p.move(to: CGPoint(x: d.x, y: d.y - 6))
            p.addLine(to: CGPoint(x: d.x + 5, y: d.y))
            p.addLine(to: CGPoint(x: d.x, y: d.y + 6))
            p.addLine(to: CGPoint(x: d.x - 5, y: d.y))
            p.closeSubpath()
        }
        return p
    }
}

/// Franja de flecos de papel de china, como la piel de una piñata.
struct FlecosPinata: View {
    var colores: [Color] = Color.fiesta
    var filas = 3

    var body: some View {
        Canvas { context, size in
            let altoFila = size.height / CGFloat(filas)
            let ancho: CGFloat = 16
            for fila in 0..<filas {
                let color = colores[fila % colores.count]
                let y = CGFloat(fila) * altoFila
                let desfase: CGFloat = fila % 2 == 0 ? 0 : ancho / 2
                var x = -desfase
                while x < size.width {
                    let tira = Path(roundedRect: CGRect(x: x + 1, y: y - altoFila * 0.4, width: ancho - 2, height: altoFila * 1.4), cornerRadius: ancho / 2)
                    context.fill(tira, with: .color(color))
                    x += ancho
                }
            }
        }
        .accessibilityHidden(true)
    }
}

/// Fondo de tarjeta de papel con borde grueso y una sombra sólida abajo.
extension View {
    func tarjetaFiesta(borde: Color = .morado, relleno: Color = .papel, radio: CGFloat = 28, conFlecos: Bool = false) -> some View {
        self
            .background {
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: radio).fill(borde.opacity(0.35)).offset(y: 8)
                    RoundedRectangle(cornerRadius: radio).fill(relleno)
                    if conFlecos {
                        FlecosPinata()
                            .frame(height: 30)
                            .clipShape(UnevenRoundedRectangle(topLeadingRadius: radio, topTrailingRadius: radio))
                    }
                    RoundedRectangle(cornerRadius: radio).strokeBorder(borde, lineWidth: 5)
                }
            }
    }

    /// Texto tipo calcomanía: contorno blanco y sombra morada para que se lea sobre el cielo.
    func calcomania() -> some View {
        self
            .shadow(color: .white, radius: 0, x: 2, y: 2)
            .shadow(color: .white, radius: 0, x: -2, y: -2)
            .shadow(color: .white, radius: 0, x: 2, y: -2)
            .shadow(color: .white, radius: 0, x: -2, y: 2)
            .shadow(color: Color.moradoOscuro.opacity(0.35), radius: 0, x: 0, y: 5)
    }

}

/// Título con cada letra de un color y un poco chueca, como letras de piñata.
struct TituloFiesta: View {
    let texto: String
    var estilo: Font.TextStyle = .largeTitle
    /// Tamaño fijo opcional; quien lo usa debe escalarlo con @ScaledMetric para respetar Dynamic Type.
    var tamano: CGFloat? = nil

    private var fuente: Font {
        if let tamano {
            return .system(size: tamano, weight: .black, design: .rounded)
        }
        return .system(estilo, design: .rounded).weight(.black)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            letras
            Text(texto)
                .font(fuente)
                .foregroundStyle(Color.morado)
                .multilineTextAlignment(.center)
                .calcomania()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(texto)
        .accessibilityAddTraits(.isHeader)
    }

    private var letras: some View {
        HStack(spacing: 1) {
            ForEach(Array(texto.enumerated()), id: \.offset) { indice, caracter in
                Text(String(caracter))
                    .foregroundStyle(Color.titulo[indice % Color.titulo.count])
                    .rotationEffect(.degrees(indice % 2 == 0 ? -4 : 4))
            }
        }
        .font(fuente)
        .fixedSize()
        .calcomania()
    }
}

/// Contador de estrellas: estrella amarilla en cápsula morada.
struct InsigniaEstrellas: View {
    let cantidad: Int
    var etiqueta: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundStyle(Color.amarillo)
                .shadow(color: Color.amarilloOscuro, radius: 0, x: 0, y: 2)
            Text(etiqueta ?? "\(cantidad)")
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .font(.system(.title2, design: .rounded).weight(.heavy))
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background {
            ZStack {
                Capsule().fill(Color.moradoOscuro).offset(y: 5)
                Capsule().fill(Color.morado)
                Capsule().strokeBorder(Color.white.opacity(0.85), lineWidth: 3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(cantidad) estrellas")
    }
}

/// Fila de estrellas pequeñas (por ejemplo, el mejor resultado de una letra).
struct FilaEstrellas: View {
    let cantidad: Int
    var total = 3
    var tamano: Font = .title3

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<total, id: \.self) { i in
                Image(systemName: i < cantidad ? "star.fill" : "star")
                    .foregroundStyle(i < cantidad ? Color.amarillo : Color.morado.opacity(0.35))
            }
        }
        .font(tamano.weight(.bold))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(cantidad) de \(total) estrellas")
    }
}

/// Barra de avance gruesa amarilla con borde morado.
struct BarraAvance: View {
    let valor: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white)
                Capsule()
                    .fill(LinearGradient(colors: [Color.amarillo, Color(hex: "FF9F1C")], startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(geo.size.width * min(max(valor, 0), 1), 24))
                Capsule().strokeBorder(Color.morado, lineWidth: 4)
            }
        }
        .frame(height: 30)
        .accessibilityHidden(true)
    }
}

/// Imagen de un personaje dentro de un marco redondo con flecos de colores.
struct RetratoPinata: View {
    let imagen: String
    var tamano: CGFloat = 160
    var gris = false

    var body: some View {
        ZStack {
            Circle()
                .fill(AngularGradient(gradient: Gradient(colors: Color.fiesta + [Color.fiesta[0]]), center: .center))
                .frame(width: tamano * 1.12, height: tamano * 1.12)
                .saturation(gris ? 0 : 1)
            Image(imagen)
                .resizable()
                .scaledToFill()
                .frame(width: tamano, height: tamano)
                .clipShape(Circle())
                .saturation(gris ? 0 : 1)
                .opacity(gris ? 0.45 : 1)
            Circle()
                .strokeBorder(Color.white, lineWidth: 5)
                .frame(width: tamano, height: tamano)
        }
        .frame(width: tamano * 1.12, height: tamano * 1.12)
    }
}
