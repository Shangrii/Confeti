import SwiftUI

/// Cierre de sesión: el niño le pega a la piñata, se rompe, caen dulces y luego ve
/// las estrellas que ganó y cuánto le falta para el siguiente personaje.
struct CierreView: View {
    @Environment(PerfilesStore.self) private var perfiles
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(Claves.umbrales) private var textoUmbrales = Valores.umbrales
    @ScaledMetric(relativeTo: .largeTitle) private var tamanoPinata: CGFloat = 300
    @ScaledMetric(relativeTo: .largeTitle) private var tamanoPersonaje: CGFloat = 150

    private let ganadas: Int
    private let antes: Int
    private let inicio: () -> Void
    private let album: () -> Void
    private let seguir: () -> Void

    @State private var golpes = 0
    @State private var rota = false
    @State private var balanceo: Double = 0
    @State private var aparecer = false
    @State private var mecer = false

    init(ganadas: Int, antes: Int, inicio: @escaping () -> Void, album: @escaping () -> Void, seguir: @escaping () -> Void) {
        self.ganadas = ganadas
        self.antes = antes
        self.inicio = inicio
        self.album = album
        self.seguir = seguir
    }

    private var umbrales: [Int] { Coleccion.umbrales(desde: textoUmbrales) }
    private var despues: Int { antes + ganadas }
    private var nueva: Pinata? { Coleccion.nueva(antes: antes, despues: despues, umbrales: umbrales) }
    /// Con Reduce Motion basta un toque: no hay balanceo que ver.
    private var golpesNecesarios: Int { reduceMotion ? 1 : Valores.golpesPinata }

    private var mensajeHablado: String {
        var texto = "¡Rompiste la piñata! Ganaste \(ganadas) estrellas."
        if let nueva {
            texto += " ¡Y desbloqueaste a \(nueva.nombre)!"
        } else if let siguiente = Coleccion.siguiente(con: despues, umbrales: umbrales) {
            texto += " Te faltan \(siguiente.faltan) estrellas para ganar a \(siguiente.pinata.nombre)."
        }
        return texto
    }

    var body: some View {
        ZStack {
            FondoFiesta()

            if rota {
                VStack(spacing: 0) {
                    Color.clear.frame(height: FondoFiesta.altoBanderines)
                    resultado
                }
                .transition(.opacity)
            } else {
                pegarle
            }

            if rota && !reduceMotion {
                ConfetiView()
            }
        }
        .onAppear {
            if !reduceMotion { mecer = true }
            Voz.shared.anunciar(golpesNecesarios == 1
                ? "¡Muy bien! Toca la piñata para romperla."
                : "¡Muy bien! Pégale a la piñata tres veces.")
        }
    }

    // MARK: - Pegarle a la piñata

    private var pegarle: some View {
        HStack(alignment: .top, spacing: 32) {
            VStack(alignment: .leading, spacing: 28) {
                Spacer()
                TituloFiesta(texto: "¡Pégale a la piñata!")

                Label("¡Tócala!", systemImage: "hand.tap.fill")
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.rosa)
                    .calcomania()
                    .flotando(amplitud: 6, duracion: 0.9)

                HStack(spacing: 14) {
                    ForEach(0..<golpesNecesarios, id: \.self) { i in
                        Image(systemName: i < golpes ? "burst.fill" : "circle.dashed")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(i < golpes ? Color.naranja : Color.morado.opacity(0.5))
                            .scaleEffect(i < golpes ? 1.15 : 1)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .tarjetaFiesta(borde: .naranja, radio: 30)
                .accessibilityHidden(true)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: golpear) {
                VStack(spacing: 0) {
                    Capsule()
                        .fill(Color(hex: "C9A27A"))
                        .frame(width: 6, height: FondoFiesta.altoBanderines + 50)
                    PinataEstrella()
                        .frame(width: tamanoPinata, height: tamanoPinata)
                }
                .rotationEffect(.degrees(mecer ? 4 : -4), anchor: .top)
                .animation(reduceMotion ? nil : .easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: mecer)
                .rotationEffect(.degrees(balanceo), anchor: .top)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .accessibilityLabel("Piñata")
            .accessibilityValue("Faltan \(golpesNecesarios - golpes) golpes")
            .accessibilityHint("Tócala para pegarle")
        }
        .padding(.horizontal, 48)
        .ignoresSafeArea(edges: .top)
    }

    private func golpear() {
        guard !rota else { return }
        golpes += 1
        Sonidos.shared.reproducir(.golpe)

        if golpes >= golpesNecesarios {
            romper()
            return
        }
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.16, dampingFraction: 0.5)) {
            balanceo = golpes % 2 == 1 ? 24 : -24
        }
        Task {
            try? await Task.sleep(for: .milliseconds(170))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.3)) {
                balanceo = 0
            }
        }
    }

    private func romper() {
        Sonidos.shared.reproducir(.romper)
        if let id = perfiles.activoID {
            perfiles.actualizar(id) { $0.pinatasRotas += 1 }
        }
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.35)) {
            rota = true
        }
        if reduceMotion {
            aparecer = true
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55).delay(0.3)) {
                aparecer = true
            }
        }
        if nueva != nil {
            Task {
                try? await Task.sleep(for: .milliseconds(700))
                Sonidos.shared.reproducir(.desbloqueo)
            }
        }
        Voz.shared.anunciar(mensajeHablado)
    }

    // MARK: - Resultado

    private var resultado: some View {
        VStack(spacing: 20) {
            ZStack {
                PinataEstrella(rota: true)
                    .frame(width: 200, height: 200)
                ExplosionDulces(sinMovimiento: reduceMotion)
            }
            .frame(height: 170)

            ViewThatFits {
                HStack(alignment: .center, spacing: 32) {
                    resumen
                    tarjetaPinata
                }
                VStack(spacing: 20) {
                    resumen
                    tarjetaPinata
                }
            }
            .padding(.horizontal, 40)
            .frame(maxHeight: .infinity)

            HStack(spacing: 18) {
                Button(action: inicio) {
                    Label("Inicio", systemImage: "house.fill")
                }
                .buttonStyle(BotonCaramelo(color: .blanco))
                .accessibilityLabel("Volver al inicio")

                Button(action: album) {
                    Label("Mis piñatas", systemImage: "square.grid.2x2.fill")
                }
                .buttonStyle(BotonCaramelo(color: .amarillo))

                Spacer()

                Button(action: seguir) {
                    Label("Seguir jugando", systemImage: "arrow.right")
                }
                .buttonStyle(BotonCaramelo(color: .rosa, grande: true))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
        }
    }

    private var resumen: some View {
        VStack(spacing: 14) {
            Text("¡Ganaste!")
                .font(.system(.largeTitle, design: .rounded).weight(.black))
                .foregroundStyle(Color.morado)
                .accessibilityAddTraits(.isHeader)

            HStack(spacing: 10) {
                Image(systemName: "star.fill")
                    .foregroundStyle(Color.amarillo)
                    .shadow(color: Color.amarilloOscuro, radius: 0, x: 0, y: 3)
                Text("+\(ganadas)")
                    .foregroundStyle(.white)
            }
            .font(.system(size: 64, weight: .black, design: .rounded))
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 26).fill(Color.moradoOscuro).offset(y: 7)
                    RoundedRectangle(cornerRadius: 26).fill(Color.morado)
                    RoundedRectangle(cornerRadius: 26).strokeBorder(Color.white, lineWidth: 4)
                }
            }
            .scaleEffect(aparecer ? 1 : 0.4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Ganaste \(ganadas) estrellas")

            Label("Total: \(despues) estrellas", systemImage: "star.circle.fill")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Color.morado)
        }
        .padding(28)
        .frame(maxWidth: 420)
        .tarjetaFiesta(borde: .morado)
    }

    @ViewBuilder
    private var tarjetaPinata: some View {
        if let nueva {
            VStack(spacing: 10) {
                Text("¡Nueva piñata!")
                    .font(.system(.title, design: .rounded).weight(.black))
                    .foregroundStyle(Color.rosa)
                ZStack {
                    RayosSol()
                        .frame(width: tamanoPersonaje * 1.8, height: tamanoPersonaje * 1.8)
                    RetratoPinata(imagen: nueva.imagen, tamano: tamanoPersonaje)
                        .scaleEffect(aparecer ? 1 : 0.2)
                        .rotationEffect(.degrees(aparecer ? 0 : -25))
                }
                .frame(height: tamanoPersonaje * 1.3)
                Text("¡\(nueva.nombre) ya es tuyo! Búscalo en Mis piñatas.")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.morado)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .frame(maxWidth: 440)
            .tarjetaFiesta(borde: .amarilloOscuro, relleno: Color(hex: "FFF4CF"))
            .accessibilityElement(children: .combine)
        } else if let siguiente = Coleccion.siguiente(con: despues, umbrales: umbrales) {
            VStack(spacing: 14) {
                Text("Tu siguiente piñata")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.morado)
                ZStack {
                    RetratoPinata(imagen: siguiente.pinata.imagen, tamano: tamanoPersonaje * 0.8, gris: true)
                    Image(systemName: "lock.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(Circle().fill(Color.morado))
                }
                BarraAvance(valor: aparecer ? siguiente.avance : 0)
                    .frame(maxWidth: 320)
                Label("Te faltan \(siguiente.faltan) estrellas", systemImage: "star")
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.morado)
            }
            .padding(24)
            .frame(maxWidth: 440)
            .tarjetaFiesta(borde: .naranja)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Siguiente piñata: \(siguiente.pinata.nombre). Te faltan \(siguiente.faltan) estrellas.")
        } else {
            Label("¡Tienes todas las piñatas!", systemImage: "crown.fill")
                .font(.system(.title, design: .rounded).weight(.black))
                .foregroundStyle(Color.morado)
                .padding(28)
                .tarjetaFiesta(borde: .amarilloOscuro, relleno: Color(hex: "FFF4CF"))
        }
    }
}

/// Rayos de sol alternados detrás de un personaje recién ganado. Giran despacio si se permite el movimiento.
struct RayosSol: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var girar = false

    var body: some View {
        Canvas { context, size in
            let centro = CGPoint(x: size.width / 2, y: size.height / 2)
            let radio = min(size.width, size.height) / 2
            let rayos = 16
            for k in 0..<rayos {
                let a0 = Double(k) * 2 * .pi / Double(rayos)
                let a1 = a0 + .pi / Double(rayos)
                var rebanada = Path()
                rebanada.move(to: centro)
                rebanada.addLine(to: CGPoint(x: centro.x + CGFloat(cos(a0)) * radio, y: centro.y + CGFloat(sin(a0)) * radio))
                rebanada.addLine(to: CGPoint(x: centro.x + CGFloat(cos(a1)) * radio, y: centro.y + CGFloat(sin(a1)) * radio))
                rebanada.closeSubpath()
                context.fill(rebanada, with: .color(Color.fiesta[k % Color.fiesta.count].opacity(0.55)))
            }
        }
        .rotationEffect(.degrees(girar ? 360 : 0))
        .animation(reduceMotion ? nil : .linear(duration: 24).repeatForever(autoreverses: false), value: girar)
        .onAppear {
            if !reduceMotion { girar = true }
        }
        .accessibilityHidden(true)
    }
}

#Preview("Cierre con progreso") {
    NavigationStack {
        CierreView(ganadas: 7, antes: 3, inicio: {}, album: {}, seguir: {})
    }
    .environment(PerfilesStore.vistaPrevia())
}

#Preview("Cierre con piñata nueva") {
    NavigationStack {
        CierreView(ganadas: 8, antes: 10, inicio: {}, album: {}, seguir: {})
    }
    .environment(PerfilesStore.vistaPrevia())
}
