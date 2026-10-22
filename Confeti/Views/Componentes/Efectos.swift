import SwiftUI

/// Piñata tradicional de siete picos, dibujada con figuras. `rota` la muestra abierta.
struct PinataEstrella: View {
    var rota = false

    var body: some View {
        Canvas { context, size in
            let lado = min(size.width, size.height)
            let centro = CGPoint(x: size.width / 2, y: size.height / 2)
            let radio = lado * 0.2
            let picos = 7

            for k in 0..<picos {
                let angulo = -Double.pi / 2 + Double(k) * 2 * .pi / Double(picos)
                let separacion: Double = rota ? 0.12 : 0
                let empuje: CGFloat = rota ? lado * 0.06 : 0
                let base = CGPoint(x: centro.x + CGFloat(cos(angulo)) * empuje, y: centro.y + CGFloat(sin(angulo)) * empuje)
                dibujarPico(en: &context, base: base, angulo: angulo + (k % 2 == 0 ? separacion : -separacion), radio: radio, largo: lado * 0.46, color: Color.fiesta[k % Color.fiesta.count])
            }

            if !rota {
                let cuerpo = Path(ellipseIn: CGRect(x: centro.x - radio, y: centro.y - radio, width: radio * 2, height: radio * 2))
                context.fill(cuerpo, with: .color(Color(hex: "FF5DA2")))
                var franjas = context
                franjas.clip(to: cuerpo)
                for (i, color) in [Color(hex: "FFD93D"), Color(hex: "4D96FF"), Color(hex: "6BCB77")].enumerated() {
                    let y = centro.y - radio + CGFloat(i + 1) * radio * 0.5
                    franjas.fill(Path(CGRect(x: centro.x - radio, y: y - radio * 0.12, width: radio * 2, height: radio * 0.24)), with: .color(color))
                }
                context.stroke(cuerpo, with: .color(Color.moradoOscuro.opacity(0.35)), lineWidth: 3)
            }
        }
        .accessibilityHidden(true)
    }

    private func dibujarPico(en context: inout GraphicsContext, base: CGPoint, angulo: Double, radio: CGFloat, largo: CGFloat, color: Color) {
        let abertura = 0.32
        let izq = CGPoint(x: base.x + CGFloat(cos(angulo - abertura)) * radio * 0.92, y: base.y + CGFloat(sin(angulo - abertura)) * radio * 0.92)
        let der = CGPoint(x: base.x + CGFloat(cos(angulo + abertura)) * radio * 0.92, y: base.y + CGFloat(sin(angulo + abertura)) * radio * 0.92)
        let punta = CGPoint(x: base.x + CGFloat(cos(angulo)) * largo, y: base.y + CGFloat(sin(angulo)) * largo)

        var cono = Path()
        cono.move(to: izq)
        cono.addLine(to: punta)
        cono.addLine(to: der)
        cono.closeSubpath()
        context.fill(cono, with: .color(color))

        // Franja blanca a media altura del pico.
        func punto(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }
        var franja = Path()
        franja.move(to: punto(izq, punta, 0.45))
        franja.addLine(to: punto(izq, punta, 0.58))
        franja.addLine(to: punto(der, punta, 0.58))
        franja.addLine(to: punto(der, punta, 0.45))
        franja.closeSubpath()
        context.fill(franja, with: .color(Color.white.opacity(0.85)))
        context.stroke(cono, with: .color(Color.moradoOscuro.opacity(0.3)), lineWidth: 2)

        // Borlas de papel en la punta.
        for (i, desvio) in [-0.5, 0.0, 0.5].enumerated() {
            let a = angulo + desvio
            var borla = Path()
            borla.move(to: punta)
            borla.addLine(to: CGPoint(x: punta.x + CGFloat(cos(a)) * largo * 0.22, y: punta.y + CGFloat(sin(a)) * largo * 0.22))
            context.stroke(borla, with: .color(Color.fiesta[(i + 2) % Color.fiesta.count]), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }
}

private struct PiezaConfeti: Identifiable {
    let id: Int
    let x: CGFloat
    let color: Color
    let retraso: Double
    let giro: Double
    let ancho: CGFloat
}

/// Lluvia de confeti. Sólo se usa si Reduce Motion está apagado.
struct ConfetiView: View {
    private let piezas: Int
    @State private var caer = false
    @State private var lista: [PiezaConfeti] = []

    init(piezas: Int = 80) {
        self.piezas = piezas
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(lista) { pieza in
                RoundedRectangle(cornerRadius: 2)
                    .fill(pieza.color)
                    .frame(width: pieza.ancho, height: pieza.ancho * 0.5)
                    .rotationEffect(.degrees(caer ? pieza.giro : 0))
                    .position(x: pieza.x * geo.size.width, y: caer ? geo.size.height + 40 : -40)
                    .animation(.easeIn(duration: 2.8).delay(pieza.retraso), value: caer)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            lista = (0..<piezas).map { i in
                PiezaConfeti(
                    id: i,
                    x: CGFloat.random(in: 0...1),
                    color: Color.fiesta.randomElement() ?? Color.amarillo,
                    retraso: Double.random(in: 0...0.9),
                    giro: Double.random(in: 180...900),
                    ancho: CGFloat.random(in: 9...17)
                )
            }
            caer = true
        }
    }
}

private struct PiezaDulce: Identifiable {
    let id: Int
    let dx: CGFloat
    let dy: CGFloat
    let giro: Double
    let color: Color
    let paleta: Bool
}

/// Dulces que salen volando de la piñata rota y caen al pasto.
/// Con Reduce Motion aparecen ya en su lugar, sin volar.
struct ExplosionDulces: View {
    private let sinMovimiento: Bool
    @State private var abierto = false
    @State private var lista: [PiezaDulce] = []

    init(sinMovimiento: Bool) {
        self.sinMovimiento = sinMovimiento
    }

    var body: some View {
        ZStack {
            ForEach(lista) { pieza in
                DulceView(color: pieza.color, paleta: pieza.paleta)
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(abierto ? pieza.giro : 0))
                    .offset(x: abierto ? pieza.dx : 0, y: abierto ? pieza.dy : 0)
                    .opacity(abierto ? 1 : 0)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            lista = (0..<26).map { i in
                let angulo = Double.random(in: 0...(2 * .pi))
                let distancia = CGFloat.random(in: 120...320)
                return PiezaDulce(
                    id: i,
                    dx: CGFloat(cos(angulo)) * distancia,
                    dy: CGFloat(sin(angulo)) * distancia * 0.6 + 140,
                    giro: Double.random(in: -200...200),
                    color: Color.fiesta[i % Color.fiesta.count],
                    paleta: i % 4 == 0
                )
            }
            if sinMovimiento {
                abierto = true
            } else {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) {
                    abierto = true
                }
            }
        }
    }
}

/// Un dulce envuelto o una paleta.
struct DulceView: View {
    let color: Color
    var paleta = false

    var body: some View {
        Canvas { context, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = min(size.width, size.height) * 0.26
            if paleta {
                var palo = Path()
                palo.move(to: c)
                palo.addLine(to: CGPoint(x: c.x, y: size.height))
                context.stroke(palo, with: .color(.white), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                let disco = Path(ellipseIn: CGRect(x: c.x - r * 1.3, y: c.y - r * 1.6, width: r * 2.6, height: r * 2.6))
                context.fill(disco, with: .color(color))
                context.stroke(disco, with: .color(.white), lineWidth: 3)
            } else {
                for lado in [-1.0, 1.0] {
                    var lazo = Path()
                    lazo.move(to: CGPoint(x: c.x + CGFloat(lado) * r * 0.8, y: c.y))
                    lazo.addLine(to: CGPoint(x: c.x + CGFloat(lado) * r * 2, y: c.y - r * 0.8))
                    lazo.addLine(to: CGPoint(x: c.x + CGFloat(lado) * r * 2, y: c.y + r * 0.8))
                    lazo.closeSubpath()
                    context.fill(lazo, with: .color(color.opacity(0.75)))
                }
                let cuerpo = Path(ellipseIn: CGRect(x: c.x - r * 1.1, y: c.y - r * 0.8, width: r * 2.2, height: r * 1.6))
                context.fill(cuerpo, with: .color(color))
                context.stroke(cuerpo, with: .color(.white), lineWidth: 2.5)
            }
        }
    }
}

/// Estrellitas que salen disparadas alrededor de algo que salió muy bien.
struct DestelloEstrellas: View {
    @State private var abierto = false

    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { i in
                let angulo = Double(i) * 2 * .pi / 10
                Image(systemName: "star.fill")
                    .font(.system(size: i % 2 == 0 ? 34 : 24))
                    .foregroundStyle(i % 2 == 0 ? Color.amarillo : Color.fiesta[i % Color.fiesta.count])
                    .offset(x: abierto ? CGFloat(cos(angulo)) * 260 : 0, y: abierto ? CGFloat(sin(angulo)) * 220 : 0)
                    .scaleEffect(abierto ? 1 : 0.2)
                    .opacity(abierto ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) {
                abierto = true
            }
        }
    }
}
