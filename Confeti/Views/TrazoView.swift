import SwiftUI

/// Lo que necesita el lienzo para dibujarse. Se arma en `body` para que SwiftUI vuelva a dibujar
/// cada vez que cambian los puntos del dedo.
private struct DatosLienzo {
    let puntos: [PuntoTrazado]
    let rutas: [Path]
    let objetivos: [[CGPoint]]
    let area: CGRect
    let parte: Int
    let estrellas: Int
    let hayResultado: Bool
    let nivel: NivelAyuda
}

struct TrazoView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(PerfilesStore.self) private var perfiles

    @AppStorage(Claves.tolerancia) private var toleranciaRelativa = Valores.tolerancia
    @AppStorage(Claves.cobertura1) private var cobertura1 = Valores.cobertura1
    @AppStorage(Claves.cobertura2) private var cobertura2 = Valores.cobertura2
    @AppStorage(Claves.precision2) private var precision2 = Valores.precision2
    @AppStorage(Claves.cobertura3) private var cobertura3 = Valores.cobertura3
    @AppStorage(Claves.precision3) private var precision3 = Valores.precision3

    @State private var modelo: TrazoViewModel
    @State private var parpadeo = false
    @State private var intento = 0
    @State private var salto = false

    private let nivel: NivelAyuda
    private let esUltimo: Bool
    private let minimoEstrellas: Int
    private let anuncioPrevio: String?
    private let alEvaluar: (Int) -> Void
    private let alTerminar: () -> Void

    /// - Parameters:
    ///   - minimoEstrellas: si el resultado queda abajo, en lugar de "Siguiente" aparece "Otra vez".
    ///   - alEvaluar: se llama con las estrellas de cada intento, para guardarlas en cuanto se ganan.
    ///   - alTerminar: se llama al tocar "Siguiente".
    init(trazo: Trazo, nivel: NivelAyuda, esUltimo: Bool, minimoEstrellas: Int = 1, anuncioPrevio: String? = nil,
         alEvaluar: @escaping (Int) -> Void, alTerminar: @escaping () -> Void) {
        _modelo = State(initialValue: TrazoViewModel(trazo: trazo))
        self.nivel = nivel
        self.esUltimo = esUltimo
        self.minimoEstrellas = minimoEstrellas
        self.anuncioPrevio = anuncioPrevio
        self.alEvaluar = alEvaluar
        self.alTerminar = alTerminar
    }

    private var cortes: Cortes {
        Cortes(cobertura1: cobertura1, cobertura2: cobertura2, precision2: precision2, cobertura3: cobertura3, precision3: precision3)
    }

    private var instruccion: String {
        let nombre = modelo.trazo.nombreHablado
        let partes = modelo.trazo.esMultiTrazo
            ? " Tiene \(modelo.trazo.trazos.count) partes: levanta el dedo al terminar cada una."
            : ""
        switch nivel {
        case .completa: return "Traza \(nombre) empezando en el punto que parpadea y sigue la flecha.\(partes)"
        case .puntos: return "Traza \(nombre) siguiendo los puntitos.\(partes)"
        case .inicio: return "Traza \(nombre) empezando en el punto. Ahora la línea no se ve: tú puedes.\(partes)"
        case .ninguna: return "Escribe \(nombre) tú solito, sin ayuda.\(partes)"
        }
    }

    /// Si no llegó al mínimo, se muestra "Casi" aunque haya ganado estrellas.
    private var retroMostrada: Retroalimentacion? {
        guard let resultado = modelo.resultado else { return nil }
        return resultado.estrellas < minimoEstrellas ? .casi : resultado.retroalimentacion
    }

    var body: some View {
        VStack(spacing: 14) {
            barraSuperior
            hoja
            barraInferior
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .onAppear {
            iniciarParpadeo()
            Voz.shared.anunciar(anuncioPrevio.map { $0 + " " + instruccion } ?? instruccion)
        }
    }

    // MARK: - Hoja de trazo

    private var hoja: some View {
        GeometryReader { geo in
            ZStack {
                lienzo
                guiaInicio
                if modelo.estrellas == 3 && !reduceMotion {
                    DestelloEstrellas()
                        .id(intento)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                modelo.configurar(en: geo.size, toleranciaRelativa: toleranciaRelativa)
            }
            .onChange(of: geo.size) { _, nuevo in
                modelo.configurar(en: nuevo, toleranciaRelativa: toleranciaRelativa)
            }
        }
        .overlay(alignment: .topLeading) {
            if nivel != .completa {
                Text(modelo.trazo.id)
                    .font(.system(.largeTitle, design: .rounded).weight(.black))
                    .foregroundStyle(Color.morado)
                    .frame(minWidth: 70, minHeight: 70)
                    .tarjetaFiesta(borde: .amarilloOscuro, relleno: Color(hex: "FFF4CF"), radio: 18)
                    .padding(.top, 44)
                    .padding(.leading, 20)
                    .accessibilityLabel("Modelo: \(modelo.trazo.nombreHablado)")
            }
        }
        .tarjetaFiesta(borde: .morado, relleno: .papel, radio: 36, conFlecos: true)
    }

    private var lienzo: some View {
        let datos = DatosLienzo(
            puntos: modelo.puntos,
            rutas: modelo.rutas,
            objetivos: modelo.objetivos,
            area: modelo.areaLetra,
            parte: modelo.parte,
            estrellas: modelo.estrellas,
            hayResultado: modelo.resultado != nil,
            nivel: nivel
        )
        return Canvas { context, _ in
            TrazoView.dibujar(en: &context, datos: datos)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { valor in
                    if modelo.agregar(valor.location) {
                        Sonidos.shared.reproducir(.fuera)
                    }
                }
                .onEnded { valor in levantar(en: valor.location) }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Área para trazar \(modelo.trazo.nombreHablado)")
        .accessibilityValue(modelo.haTrazado ? "\(modelo.porcentajeDentro) por ciento del trazo dentro de la línea" : "Sin empezar")
        .accessibilityHint("Ayuda: \(nivel.descripcion). Desliza el dedo desde el punto marcado.")
        .accessibilityAddTraits(.allowsDirectInteraction)
    }

    private static func dibujar(en context: inout GraphicsContext, datos: DatosLienzo) {
        let area = datos.area
        guard area.width > 0 else { return }

        // Renglones de cuaderno: arriba, en medio y abajo de la letra.
        for (indice, y) in [area.minY, area.midY, area.maxY].enumerated() {
            var renglon = Path()
            renglon.move(to: CGPoint(x: area.minX - 40, y: y))
            renglon.addLine(to: CGPoint(x: area.maxX + 40, y: y))
            let estilo = StrokeStyle(lineWidth: 2, dash: indice == 1 ? [8, 8] : [])
            context.stroke(renglon, with: .color(Color.azul.opacity(0.18)), style: estilo)
        }

        if datos.estrellas == 3 {
            for ruta in datos.rutas {
                context.stroke(ruta, with: .color(Color.verde.opacity(0.3)), style: StrokeStyle(lineWidth: 36, lineCap: .round, lineJoin: .round))
            }
        }

        // Después de evaluar siempre se enseña la letra, para que el niño compare.
        let guia: NivelAyuda = datos.hayResultado ? .completa : datos.nivel
        switch guia {
        case .completa:
            for (indice, ruta) in datos.rutas.enumerated() {
                let opacidad: Double = indice == datos.parte || datos.hayResultado ? 0.55 : 0.25
                context.stroke(ruta, with: .color(Color.gray.opacity(opacidad)), style: StrokeStyle(lineWidth: 6, lineCap: .round, dash: [2, 14]))
            }
        case .puntos:
            for (indice, parte) in datos.objetivos.enumerated() where indice >= datos.parte {
                for (k, punto) in parte.enumerated() where k % 6 == 0 {
                    context.fill(Path(ellipseIn: CGRect(x: punto.x - 6, y: punto.y - 6, width: 12, height: 12)), with: .color(Color.gray.opacity(0.55)))
                }
            }
        case .inicio, .ninguna:
            break
        }

        // Sin guía, el acierto se esconde hasta soltar el dedo: así el niño escribe sin "ver la respuesta".
        let ocultar = datos.nivel == .ninguna && !datos.hayResultado
        for punto in datos.puntos {
            let diametro: CGFloat
            let color: Color
            if ocultar {
                diametro = 15
                color = Color.morado.opacity(0.75)
            } else if punto.dentro {
                diametro = 19
                color = Color.fiesta[(punto.numero / 5) % Color.fiesta.count]
            } else {
                diametro = 9
                color = Color.gray.opacity(0.7)
            }
            let rect = CGRect(x: punto.posicion.x - diametro / 2, y: punto.posicion.y - diametro / 2, width: diametro, height: diametro)
            context.fill(Path(ellipseIn: rect), with: .color(color))
        }
    }

    @ViewBuilder
    private var guiaInicio: some View {
        if nivel != .ninguna, let inicio = modelo.inicioParte {
            if nivel == .completa, let angulo = modelo.anguloParte {
                Image(systemName: "arrow.right")
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(Color.morado.opacity(0.8))
                    .rotationEffect(.radians(angulo))
                    .position(x: inicio.x + CGFloat(cos(angulo)) * 58, y: inicio.y + CGFloat(sin(angulo)) * 58)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            ZStack {
                Circle().fill(Color.morado)
                Circle().strokeBorder(Color.white, lineWidth: 4)
                if modelo.totalPartes > 1 {
                    Text("\(modelo.parte + 1)")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 38, height: 38)
            .scaleEffect(reduceMotion ? 1 : (parpadeo ? 1.25 : 0.85))
            .opacity(reduceMotion ? 1 : (parpadeo ? 1 : 0.6))
            .position(inicio)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    // MARK: - Barras

    private var barraSuperior: some View {
        HStack(spacing: 16) {
            BotonEscuchar(texto: instruccion)

            Label(nivel.descripcion, systemImage: nivel.icono)
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Capsule().fill(Color.turquesa))
                .accessibilityLabel("Ayuda: \(nivel.descripcion)")

            Spacer()

            if let retro = retroMostrada {
                GloboMensaje(texto: retro.texto, icono: retro.icono, color: retro == .casi ? .naranja : .morado)
                    .transition(.scale.combined(with: .opacity))
            } else if modelo.totalPartes > 1 {
                GloboMensaje(texto: "Parte \(min(modelo.parte + 1, modelo.totalPartes)) de \(modelo.totalPartes)", icono: "pencil.and.outline")
            }

            Spacer()

            estrellas
        }
    }

    private var estrellas: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { indice in
                Image(systemName: indice < modelo.estrellas ? "star.fill" : "star")
                    .font(.title.weight(.bold))
                    .foregroundStyle(indice < modelo.estrellas ? Color.amarillo : Color.white)
                    .scaleEffect(indice < modelo.estrellas ? 1.15 : 1)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background {
            ZStack {
                Capsule().fill(Color.moradoOscuro).offset(y: 5)
                Capsule().fill(Color.morado)
                Capsule().strokeBorder(Color.white.opacity(0.85), lineWidth: 3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Estrellas")
        .accessibilityValue("\(modelo.estrellas) de 3")
    }

    private var barraInferior: some View {
        HStack {
            Button(action: borrar) {
                Label("Borrar", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(BotonCaramelo(color: .blanco))
            .accessibilityLabel("Borrar trazo")
            .accessibilityHint("Vuelve a empezar desde cero")

            Spacer()

            porrista

            Spacer()

            if let resultado = modelo.resultado, resultado.estrellas < minimoEstrellas {
                Button(action: borrar) {
                    Label("Otra vez", systemImage: "arrow.uturn.left")
                }
                .buttonStyle(BotonCaramelo(color: .naranja))
                .accessibilityHint("Intenta esta letra de nuevo")
            } else {
                Button(action: alTerminar) {
                    Label(esUltimo ? "Terminar" : "Siguiente", systemImage: "arrow.right")
                }
                .buttonStyle(BotonCaramelo(color: .morado))
                .disabled(modelo.resultado == nil)
                .accessibilityHint("Se activa cuando terminas de trazar")
            }
        }
    }

    /// La piñata del niño lo acompaña abajo y salta de gusto cuando le sale bien.
    private var porrista: some View {
        let id = perfiles.activo?.pinataActiva ?? Coleccion.pinatas[0].id
        return RetratoPinata(imagen: Coleccion.pinata(id: id).imagen, tamano: 70)
            .offset(y: salto ? -34 : 0)
            .rotationEffect(.degrees(salto ? -8 : 0))
            .accessibilityHidden(true)
    }

    // MARK: - Acciones

    private func levantar(en punto: CGPoint) {
        let animacion: Animation? = reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6)
        let accion = withAnimation(animacion) { modelo.levantar(en: punto, cortes: cortes) }

        switch accion {
        case .nada:
            break
        case .incompleta:
            Voz.shared.anunciar("Sigue la línea hasta el final.")
        case .siguienteParte:
            Sonidos.shared.reproducir(.cuenta)
            Voz.shared.anunciar("¡Bien! Ahora la parte \(modelo.parte + 1).")
        case .evaluado(let evaluacion):
            intento += 1
            let alcanzo = evaluacion.estrellas >= minimoEstrellas
            Sonidos.shared.reproducir(alcanzo ? evaluacion.retroalimentacion.sonido : .casi)
            Voz.shared.anunciar(alcanzo ? evaluacion.retroalimentacion.texto : "Casi, va otra vez. Toca el botón naranja.")
            alEvaluar(evaluacion.estrellas)
            if alcanzo && !reduceMotion {
                saltar(veces: evaluacion.estrellas)
            }
        }
    }

    private func borrar() {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            modelo.reiniciar()
        }
    }

    private func saltar(veces: Int) {
        Task {
            for _ in 0..<max(veces, 1) {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.45)) { salto = true }
                try? await Task.sleep(for: .milliseconds(220))
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { salto = false }
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    private func iniciarParpadeo() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            parpadeo = true
        }
    }
}

#Preview("O · guía completa") {
    ZStack {
        FondoFiesta()
        TrazoView(trazo: Trazo.letra("O")!, nivel: .completa, esUltimo: false, alEvaluar: { _ in }, alTerminar: {})
    }
    .environment(PerfilesStore.vistaPrevia())
}

#Preview("A · puntos") {
    ZStack {
        FondoFiesta()
        TrazoView(trazo: Trazo.letra("A")!, nivel: .puntos, esUltimo: false, alEvaluar: { _ in }, alTerminar: {})
    }
    .environment(PerfilesStore.vistaPrevia())
}

#Preview("L · sin guía") {
    ZStack {
        FondoFiesta()
        TrazoView(trazo: Trazo.letra("L")!, nivel: .ninguna, esUltimo: true, minimoEstrellas: 2, alEvaluar: { _ in }, alTerminar: {})
    }
    .environment(PerfilesStore.vistaPrevia())
}
