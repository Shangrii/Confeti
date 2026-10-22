import SwiftUI

/// "Cuenta y traza": el niño toca cada dibujo para contarlo y luego traza el número.
struct CuentaView: View {
    @Environment(PerfilesStore.self) private var perfiles
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var tamanoObjeto: CGFloat = 120

    private struct Ronda {
        let cantidad: Int
        let palabra: PalabraJuego
    }

    private let terminar: (Int, Int) -> Void

    @State private var rondas: [Ronda] = []
    @State private var ronda = 0
    @State private var contados: [Int] = []
    @State private var trazando = false
    @State private var ganadas = 0
    @State private var antes = 0

    init(terminar: @escaping (Int, Int) -> Void) {
        self.terminar = terminar
    }

    private var actual: Ronda? { rondas[safe: ronda] }
    private var completo: Bool {
        guard let actual else { return false }
        return contados.count == actual.cantidad
    }

    var body: some View {
        ZStack {
            FondoFiesta()

            VStack(spacing: 0) {
                EncabezadoPantalla("Cuenta y traza") {
                    EstrellasJugador()
                }
                if let actual {
                    if trazando {
                        vistaTrazo(actual)
                    } else {
                        vistaContar(actual)
                    }
                }
            }
        }
        .onAppear(perform: preparar)
    }

    // MARK: - Contar

    private func vistaContar(_ actual: Ronda) -> some View {
        VStack(spacing: 22) {
            EncabezadoJuego(pregunta: "¿\(actual.palabra.cuantos) \(actual.palabra.plural) hay?", ronda: ronda, total: rondas.count)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: tamanoObjeto + 20), spacing: 24)], spacing: 24) {
                ForEach(0..<actual.cantidad, id: \.self) { i in
                    objeto(i, palabra: actual.palabra)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 52)
            .padding(.bottom, 28)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tarjetaFiesta(borde: .naranja, relleno: .white, radio: 36, conFlecos: true)

            HStack(spacing: 20) {
                Text(completo ? "¡Hay \(actual.cantidad)!" : (contados.isEmpty ? "Toca cada uno para contarlo" : "Llevas \(contados.count)"))
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.naranja)
                    .calcomania()
                Spacer()
                if completo {
                    Button(action: irATrazar) {
                        Label("Trazar el \(actual.cantidad)", systemImage: "pencil.and.outline")
                    }
                    .buttonStyle(BotonCaramelo(color: .naranja))
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 8)
        .padding(.bottom, 32)
    }

    private func objeto(_ i: Int, palabra: PalabraJuego) -> some View {
        let posicion = contados.firstIndex(of: i)
        return Button(action: { contar(i, palabra: palabra) }) {
            Image(palabra.imagen)
                .resizable()
                .scaledToFit()
                .frame(width: tamanoObjeto, height: tamanoObjeto)
                .scaleEffect(posicion == nil ? 1 : 0.92)
                .overlay(alignment: .topTrailing) {
                    if let posicion {
                        Text("\(posicion + 1)")
                            .font(.system(.title, design: .rounded).weight(.black))
                            .foregroundStyle(.white)
                            .frame(width: 52, height: 52)
                            .background(Circle().fill(Color.naranja))
                            .overlay(Circle().strokeBorder(Color.white, lineWidth: 4))
                            .offset(x: 10, y: -10)
                            .transition(.scale)
                    }
                }
        }
        .buttonStyle(BotonTarjeta())
        .disabled(posicion != nil)
        .accessibilityLabel(palabra.texto)
        .accessibilityValue(posicion.map { "Contado: \($0 + 1)" } ?? "Sin contar")
    }

    // MARK: - Trazar

    private func vistaTrazo(_ actual: Ronda) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                ForEach(0..<actual.cantidad, id: \.self) { _ in
                    Image(actual.palabra.imagen)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }
            .padding(.horizontal, 28)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Hay \(actual.cantidad) \(actual.cantidad == 1 ? actual.palabra.texto.lowercased() : actual.palabra.plural)")

            if let trazo = Trazo.numero(actual.cantidad) {
                TrazoView(
                    trazo: trazo,
                    nivel: perfiles.activo?.nivel(de: trazo.clave) ?? .completa,
                    esUltimo: ronda == rondas.count - 1,
                    anuncioPrevio: "Ahora traza el \(actual.cantidad).",
                    alEvaluar: { estrellas in guardar(estrellas, en: trazo) },
                    alTerminar: siguiente
                )
                .id(ronda)
            }
        }
    }

    // MARK: - Lógica

    private func preparar() {
        guard rondas.isEmpty else { return }
        antes = perfiles.activo?.estrellas ?? 0
        let cantidades = Array((1...9).shuffled().prefix(Valores.rondasPorJuego))
        rondas = cantidades.map { Ronda(cantidad: $0, palabra: ColeccionPalabras.catalogo.randomElement() ?? ColeccionPalabras.catalogo[0]) }
        anunciarRonda()
    }

    private func anunciarRonda() {
        guard let actual else { return }
        Voz.shared.anunciar("¿\(actual.palabra.cuantos) \(actual.palabra.plural) hay? Toca cada uno para contarlo.")
    }

    private func contar(_ i: Int, palabra: PalabraJuego) {
        guard let actual, !contados.contains(i) else { return }
        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.6)) {
            contados.append(i)
        }
        Sonidos.shared.reproducir(.cuenta)
        if contados.count == actual.cantidad {
            Sonidos.shared.reproducir(.correcto)
            let cuantos = actual.cantidad == 1 ? palabra.conArticulo : "\(actual.cantidad) \(palabra.plural)"
            Voz.shared.anunciar("\(contados.count). ¡Hay \(cuantos)! Toca el botón para trazar el \(actual.cantidad).")
        } else {
            Voz.shared.decir("\(contados.count)")
        }
    }

    private func irATrazar() {
        withAnimation(.easeOut(duration: 0.25)) {
            trazando = true
        }
    }

    private func guardar(_ estrellas: Int, en trazo: Trazo) {
        guard let id = perfiles.activoID else { return }
        ganadas += estrellas
        perfiles.actualizar(id) { perfil in
            perfil.registrar(estrellas: estrellas, en: trazo.clave)
            perfil.estrellas += estrellas
        }
    }

    private func siguiente() {
        if ronda + 1 < rondas.count {
            ronda += 1
            contados = []
            trazando = false
            anunciarRonda()
        } else {
            terminar(ganadas, antes)
        }
    }
}
