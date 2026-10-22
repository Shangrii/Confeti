import SwiftUI

/// El jardín de las piñatas: cielo, sol sonriente, nubes que pasean, colinas con árboles,
/// cerca, flores, mariposas y papel picado arriba. Fondo de todas las pantallas.
struct FondoFiesta: View {
    var banderines = true

    static let altoBanderines: CGFloat = 64

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [Color(hex: "4FC3F7"), Color.cieloAlto, Color(hex: "C8EEFF")],
                    startPoint: .top,
                    endPoint: .bottom
                )

                SolSonriente()
                    .frame(width: 190, height: 190)
                    .position(x: w - 120, y: 150)

                NubeView(escala: 1.15, recorrido: 50, duracion: 11)
                    .position(x: w * 0.17, y: 175)
                NubeView(escala: 0.8, recorrido: 70, duracion: 14)
                    .position(x: w * 0.52, y: 115)
                NubeView(escala: 0.6, recorrido: 40, duracion: 9)
                    .position(x: w * 0.78, y: 285)

                Canvas { context, size in
                    Jardin.dibujar(en: &context, tamano: size)
                }

                Mariposa(color: Color(hex: "FF5DA2"), recorrido: CGSize(width: 120, height: 50), duracion: 6)
                    .position(x: w * 0.22, y: h * 0.70)
                Mariposa(color: Color(hex: "FFD93D"), recorrido: CGSize(width: -90, height: 40), duracion: 7.5)
                    .position(x: w * 0.74, y: h * 0.66)
                Mariposa(color: Color(hex: "B983FF"), recorrido: CGSize(width: 70, height: -60), duracion: 5)
                    .position(x: w * 0.48, y: h * 0.78)

                if banderines {
                    PapelPicado(cantidad: max(Int(w / 105), 8))
                        .frame(width: w, height: Self.altoBanderines)
                }
            }
            .frame(width: w, height: h)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Dibujo fijo de las colinas, árboles, cerca, flores y pasto.
enum Jardin {
    static func dibujar(en context: inout GraphicsContext, tamano: CGSize) {
        let w = tamano.width
        let h = tamano.height

        // Colina del fondo con árboles.
        let fondo = colina(w: w, h: h, base: 0.70, subida: 0.10, ondas: 2, fase: 0.2)
        context.fill(fondo, with: .color(Color(hex: "A8DF8E")))
        for (x, escala) in [(0.10, 0.9), (0.33, 1.15), (0.62, 0.85), (0.90, 1.05)] as [(CGFloat, CGFloat)] {
            arbol(en: &context, base: CGPoint(x: w * x, y: h * 0.69), escala: escala)
        }

        // Colina de en medio.
        let medio = colina(w: w, h: h, base: 0.80, subida: 0.07, ondas: 3, fase: 0.6)
        context.fill(medio, with: .color(Color.pasto))

        // Colina de enfrente con la cerca.
        let frente = colina(w: w, h: h, base: 0.88, subida: 0.05, ondas: 2, fase: 0)
        context.fill(frente, with: .color(Color.pastoOscuro))
        cerca(en: &context, desde: 0, hasta: w * 0.34, y: h * 0.875)

        // Pasto y flores sobre la colina de enfrente.
        var pasto = Path()
        var x: CGFloat = 12
        var k = 0
        while x < w {
            let y = h * (0.915 + 0.03 * CGFloat((k * 7) % 5) / 5)
            pasto.move(to: CGPoint(x: x - 6, y: y))
            pasto.addLine(to: CGPoint(x: x - 3, y: y - 14))
            pasto.move(to: CGPoint(x: x, y: y))
            pasto.addLine(to: CGPoint(x: x + 1, y: y - 18))
            pasto.move(to: CGPoint(x: x + 6, y: y))
            pasto.addLine(to: CGPoint(x: x + 5, y: y - 12))
            x += 46 + CGFloat((k * 13) % 30)
            k += 1
        }
        context.stroke(pasto, with: .color(Color(hex: "3F8A2E")), style: StrokeStyle(lineWidth: 3, lineCap: .round))

        let flores: [CGFloat] = [0.40, 0.47, 0.55, 0.63, 0.70, 0.78, 0.86, 0.94, 0.06, 0.15, 0.25]
        for (i, fx) in flores.enumerated() {
            let centro = CGPoint(x: w * fx, y: h * (0.93 + 0.025 * CGFloat(i % 3)))
            flor(en: &context, centro: centro, color: Color.fiesta[i % Color.fiesta.count], radio: i % 2 == 0 ? 10 : 8)
        }
    }

    private static func colina(w: CGFloat, h: CGFloat, base: CGFloat, subida: CGFloat, ondas: Int, fase: CGFloat) -> Path {
        var p = Path()
        let y0 = h * base
        let paso = w / CGFloat(ondas)
        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: 0, y: y0))
        for i in 0..<ondas {
            let x0 = CGFloat(i) * paso
            let alto: CGFloat = (i % 2 == 0 ? 1 : 0.55) * h * subida
            p.addQuadCurve(to: CGPoint(x: x0 + paso, y: y0), control: CGPoint(x: x0 + paso * (0.5 + fase * 0.3), y: y0 - alto * 2))
        }
        p.addLine(to: CGPoint(x: w, y: h))
        p.closeSubpath()
        return p
    }

    private static func arbol(en context: inout GraphicsContext, base: CGPoint, escala: CGFloat) {
        let tronco = Path(roundedRect: CGRect(x: base.x - 9 * escala, y: base.y - 60 * escala, width: 18 * escala, height: 62 * escala), cornerRadius: 5)
        context.fill(tronco, with: .color(Color(hex: "8B5226")))
        var copa = Path()
        let bolas: [(CGFloat, CGFloat, CGFloat)] = [(0, -95, 44), (-34, -70, 32), (34, -70, 32), (-18, -118, 28), (20, -116, 30)]
        for (dx, dy, r) in bolas {
            let rr = r * escala
            copa.addEllipse(in: CGRect(x: base.x + dx * escala - rr, y: base.y + dy * escala - rr, width: rr * 2, height: rr * 2))
        }
        context.fill(copa, with: .color(Color(hex: "4CAF50")))
        // Frutitas de dulce en la copa.
        let frutas: [(CGFloat, CGFloat)] = [(-20, -92), (16, -104), (28, -78), (-30, -66), (2, -126)]
        for (i, (dx, dy)) in frutas.enumerated() {
            let r: CGFloat = 6 * escala
            let c = CGPoint(x: base.x + dx * escala, y: base.y + dy * escala)
            context.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)), with: .color(Color.fiesta[(i + 1) % Color.fiesta.count]))
        }
    }

    private static func cerca(en context: inout GraphicsContext, desde: CGFloat, hasta: CGFloat, y: CGFloat) {
        var travesanos = Path()
        travesanos.addRect(CGRect(x: desde, y: y - 34, width: hasta - desde, height: 7))
        travesanos.addRect(CGRect(x: desde, y: y - 14, width: hasta - desde, height: 7))
        context.fill(travesanos, with: .color(Color(hex: "F5E6CC")))

        var tablas = Path()
        var x = desde + 8
        while x < hasta {
            tablas.move(to: CGPoint(x: x, y: y + 6))
            tablas.addLine(to: CGPoint(x: x, y: y - 44))
            tablas.addLine(to: CGPoint(x: x + 8, y: y - 54))
            tablas.addLine(to: CGPoint(x: x + 16, y: y - 44))
            tablas.addLine(to: CGPoint(x: x + 16, y: y + 6))
            tablas.closeSubpath()
            x += 28
        }
        context.fill(tablas, with: .color(.white))
        context.stroke(tablas, with: .color(Color(hex: "C9B79C")), lineWidth: 2)
    }

    static func flor(en context: inout GraphicsContext, centro: CGPoint, color: Color, radio r: CGFloat) {
        var tallo = Path()
        tallo.move(to: centro)
        tallo.addLine(to: CGPoint(x: centro.x, y: centro.y + r * 2.4))
        context.stroke(tallo, with: .color(Color(hex: "3F8A2E")), lineWidth: 3)
        for k in 0..<5 {
            let a = Double(k) * 2 * .pi / 5
            let c = CGPoint(x: centro.x + CGFloat(cos(a)) * r, y: centro.y + CGFloat(sin(a)) * r)
            context.fill(Path(ellipseIn: CGRect(x: c.x - r * 0.8, y: c.y - r * 0.8, width: r * 1.6, height: r * 1.6)), with: .color(color))
        }
        context.fill(Path(ellipseIn: CGRect(x: centro.x - r * 0.6, y: centro.y - r * 0.6, width: r * 1.2, height: r * 1.2)), with: .color(Color(hex: "FFD93D")))
    }
}

/// Sol con carita: los rayos giran despacio si se permite el movimiento.
struct SolSonriente: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var girar = false

    init() {}

    var body: some View {
        ZStack {
            Canvas { context, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                let r = min(size.width, size.height) * 0.33
                for k in 0..<12 {
                    let a = Double(k) * .pi / 6
                    var rayo = Path()
                    rayo.move(to: CGPoint(x: c.x + CGFloat(cos(a - 0.14)) * r * 1.08, y: c.y + CGFloat(sin(a - 0.14)) * r * 1.08))
                    rayo.addLine(to: CGPoint(x: c.x + CGFloat(cos(a)) * r * 1.5, y: c.y + CGFloat(sin(a)) * r * 1.5))
                    rayo.addLine(to: CGPoint(x: c.x + CGFloat(cos(a + 0.14)) * r * 1.08, y: c.y + CGFloat(sin(a + 0.14)) * r * 1.08))
                    rayo.closeSubpath()
                    context.fill(rayo, with: .color(Color(hex: "FFB703")))
                }
            }
            .rotationEffect(.degrees(girar ? 360 : 0))

            Canvas { context, size in
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                let r = min(size.width, size.height) * 0.33
                let disco = Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
                context.fill(disco, with: .color(Color(hex: "FFD93D")))
                context.stroke(disco, with: .color(Color(hex: "FFB703")), lineWidth: 6)
                for dx in [-0.35, 0.35] {
                    let ojo = CGRect(x: c.x + r * CGFloat(dx) - 6, y: c.y - r * 0.25 - 9, width: 12, height: 18)
                    context.fill(Path(ellipseIn: ojo), with: .color(Color(hex: "6B3F1D")))
                    let cachete = CGRect(x: c.x + r * CGFloat(dx) * 1.45 - 11, y: c.y + r * 0.15 - 7, width: 22, height: 14)
                    context.fill(Path(ellipseIn: cachete), with: .color(Color(hex: "FF8FAB").opacity(0.8)))
                }
                var sonrisa = Path()
                sonrisa.addArc(center: CGPoint(x: c.x, y: c.y + r * 0.05), radius: r * 0.42, startAngle: .degrees(25), endAngle: .degrees(155), clockwise: false)
                context.stroke(sonrisa, with: .color(Color(hex: "6B3F1D")), style: StrokeStyle(lineWidth: 5, lineCap: .round))
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) {
                girar = true
            }
        }
    }
}

/// Nube esponjosa que pasea de un lado a otro.
struct NubeView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var mover = false

    private let escala: CGFloat
    private let recorrido: CGFloat
    private let duracion: Double

    init(escala: CGFloat, recorrido: CGFloat, duracion: Double) {
        self.escala = escala
        self.recorrido = recorrido
        self.duracion = duracion
    }

    var body: some View {
        Canvas { context, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            var nube = Path()
            let bolas: [(CGFloat, CGFloat, CGFloat)] = [(-70, 10, 38), (-30, -14, 48), (20, -20, 54), (66, 4, 40), (0, 18, 44)]
            for (dx, dy, r) in bolas {
                let rr = r * escala
                nube.addEllipse(in: CGRect(x: c.x + dx * escala - rr, y: c.y + dy * escala - rr, width: rr * 2, height: rr * 2))
            }
            context.fill(nube, with: .color(Color(hex: "B3E5FC")))
            var copia = context
            copia.translateBy(x: 0, y: -6)
            copia.fill(nube, with: .color(.white))
        }
        .frame(width: 260 * escala, height: 150 * escala)
        .offset(x: mover ? recorrido : -recorrido)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: duracion).repeatForever(autoreverses: true)) {
                mover = true
            }
        }
    }
}

/// Mariposa que aletea y revolotea.
struct Mariposa: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var aletear = false
    @State private var volar = false

    private let color: Color
    private let recorrido: CGSize
    private let duracion: Double

    init(color: Color, recorrido: CGSize, duracion: Double) {
        self.color = color
        self.recorrido = recorrido
        self.duracion = duracion
    }

    var body: some View {
        ZStack {
            HStack(spacing: 2) {
                ala.scaleEffect(x: -1)
                ala
            }
            .scaleEffect(x: aletear ? 0.35 : 1, y: 1)
            Capsule()
                .fill(Color(hex: "5A3315"))
                .frame(width: 5, height: 22)
        }
        .frame(width: 44, height: 34)
        .offset(x: volar ? recorrido.width : 0, y: volar ? recorrido.height : 0)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.18).repeatForever(autoreverses: true)) {
                aletear = true
            }
            withAnimation(.easeInOut(duration: duracion).repeatForever(autoreverses: true)) {
                volar = true
            }
        }
    }

    private var ala: some View {
        VStack(spacing: -4) {
            Ellipse().fill(color).frame(width: 18, height: 16)
            Ellipse().fill(color.opacity(0.75)).frame(width: 13, height: 12)
        }
    }
}

extension View {
    /// Flota suavemente hacia arriba y abajo. Sin movimiento si Reduce Motion está activo.
    func flotando(amplitud: CGFloat = 8, duracion: Double = 1.6, retraso: Double = 0) -> some View {
        Flotante(amplitud: amplitud, duracion: duracion, retraso: retraso, contenido: self)
    }
}

struct Flotante<Contenido: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var arriba = false

    private let amplitud: CGFloat
    private let duracion: Double
    private let retraso: Double
    private let contenido: Contenido

    init(amplitud: CGFloat, duracion: Double, retraso: Double, contenido: Contenido) {
        self.amplitud = amplitud
        self.duracion = duracion
        self.retraso = retraso
        self.contenido = contenido
    }

    var body: some View {
        contenido
            .offset(y: arriba ? -amplitud : amplitud * 0.4)
            .rotationEffect(.degrees(arriba ? 1.5 : -1.5))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: duracion).repeatForever(autoreverses: true).delay(retraso)) {
                    arriba = true
                }
            }
    }
}
