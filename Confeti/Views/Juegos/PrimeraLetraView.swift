import SwiftUI

/// "¿Con qué empieza?": el niño ve un dibujo y elige la letra con la que empieza su nombre.
struct PrimeraLetraView: View {
    @Environment(PerfilesStore.self) private var perfiles
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var tamanoLetra: CGFloat = 96
    @ScaledMetric(relativeTo: .largeTitle) private var tamanoPalabra: CGFloat = 60

    private let terminar: (Int, Int) -> Void

    @State private var rondas: [PalabraJuego] = []
    @State private var ronda = 0
    @State private var opciones: [String] = []
    @State private var descartadas: Set<String> = []
    @State private var acerto = false
    @State private var errores = 0
    @State private var ganadas = 0
    @State private var antes = 0
    @State private var sacudida: String?
    @State private var destello = 0

    init(terminar: @escaping (Int, Int) -> Void) {
        self.terminar = terminar
    }

    private var palabra: PalabraJuego? { rondas[safe: ronda] }
    private var pregunta: String { "¿Con qué letra empieza \(palabra?.texto.lowercased() ?? "")?" }

    var body: some View {
        ZStack {
            FondoFiesta()

            VStack(spacing: 24) {
                EncabezadoPantalla("¿Con qué empieza?") {
                    EstrellasJugador()
                }
                EncabezadoJuego(pregunta: pregunta, ronda: ronda, total: rondas.count)

                if let palabra {
                    HStack(spacing: 36) {
                        dibujo(de: palabra)
                        VStack(spacing: 28) {
                            palabraConHueco(palabra)
                            HStack(spacing: 22) {
                                ForEach(opciones, id: \.self) { letra in
                                    ficha(letra, correcta: palabra.primeraLetra)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .frame(maxHeight: .infinity)
                }

                if acerto {
                    PieJuego(estrellas: estrellasPorErrores(errores), esUltima: ronda == rondas.count - 1, siguiente: siguiente)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)

            if acerto && !reduceMotion {
                DestelloEstrellas().id(destello)
            }
        }
        .onAppear(perform: preparar)
    }

    private func dibujo(de palabra: PalabraJuego) -> some View {
        Image(palabra.imagen)
            .resizable()
            .scaledToFit()
            .padding(28)
            .padding(.top, 24)
            .frame(maxWidth: 420, maxHeight: .infinity)
            .tarjetaFiesta(borde: .azul, relleno: .white, radio: 36, conFlecos: true)
            .accessibilityLabel("Dibujo de \(palabra.conArticulo)")
    }

    /// La palabra con un hueco en la primera letra: "_ATO". Al acertar se llena.
    private func palabraConHueco(_ palabra: PalabraJuego) -> some View {
        let resto = String(palabra.texto.dropFirst()).uppercased()
        return HStack(spacing: 4) {
            Text(acerto ? palabra.primeraLetra : "_")
                .foregroundStyle(acerto ? Color.verdeTexto : Color.rosa)
            Text(resto)
                .foregroundStyle(Color.morado)
        }
        .font(.system(size: tamanoPalabra, weight: .black, design: .rounded))
        .tracking(6)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .padding(.horizontal, 30)
        .padding(.vertical, 14)
        .tarjetaFiesta(borde: .morado, radio: 26)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(acerto ? palabra.texto : "Palabra sin la primera letra")
    }

    private func ficha(_ letra: String, correcta: String) -> some View {
        let esCorrecta = acerto && letra == correcta
        let descartada = descartadas.contains(letra)
        let borde: Color = esCorrecta ? .verdeTexto : (descartada ? .grisDesactivado : .azul)

        return Button(action: { elegir(letra) }) {
            Text(letra)
                .font(.system(size: tamanoLetra, weight: .black, design: .rounded))
                .foregroundStyle(descartada ? Color.grisDesactivado : (esCorrecta ? Color.verdeTexto : Color.azul))
                .frame(width: tamanoLetra * 1.4, height: tamanoLetra * 1.5)
                .tarjetaFiesta(borde: borde, relleno: esCorrecta ? Color(hex: "DDF5E4") : .white, radio: 28)
                .opacity(descartada ? 0.5 : 1)
                .overlay(alignment: .topTrailing) {
                    if esCorrecta {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(Color.verdeTexto)
                            .background(Circle().fill(Color.white))
                            .offset(x: 12, y: -12)
                    }
                }
                .scaleEffect(esCorrecta ? 1.08 : 1)
                .offset(x: sacudida == letra ? 14 : 0)
        }
        .buttonStyle(BotonTarjeta())
        .disabled(acerto || descartada)
        .accessibilityLabel("Letra \(letra)")
        .accessibilityValue(esCorrecta ? "Correcto" : (descartada ? "Ya la probaste" : ""))
    }

    private func preparar() {
        guard rondas.isEmpty else { return }
        antes = perfiles.activo?.estrellas ?? 0
        rondas = Array(ColeccionPalabras.catalogo.shuffled().prefix(Valores.rondasPorJuego))
        prepararRonda()
    }

    private func prepararRonda() {
        guard let palabra else { return }
        acerto = false
        errores = 0
        descartadas = []
        let correcta = palabra.primeraLetra
        let otras = Categoria.letras.orden.filter { $0 != correcta && $0 != "Ñ" }.shuffled().prefix(2)
        opciones = ([correcta] + otras).shuffled()
        Voz.shared.anunciar("\(pregunta) Toca la letra.")
    }

    private func elegir(_ letra: String) {
        guard !acerto, let palabra else { return }
        if letra == palabra.primeraLetra {
            let estrellas = estrellasPorErrores(errores)
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6)) {
                acerto = true
            }
            destello += 1
            ganadas += estrellas
            perfiles.sumarEstrellas(estrellas)
            Sonidos.shared.reproducir(.correcto)
            Voz.shared.anunciar("¡Sí! \(palabra.texto) empieza con \(letra).")
        } else {
            errores += 1
            descartadas.insert(letra)
            Sonidos.shared.reproducir(.casi)
            Voz.shared.anunciar("Esa es la \(letra). Escucha: \(palabra.texto.lowercased()). Intenta otra.")
            sacudir(letra)
        }
    }

    private func sacudir(_ letra: String) {
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.12, dampingFraction: 0.2)) {
            sacudida = letra
        }
        Task {
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.spring(response: 0.25, dampingFraction: 0.3)) {
                sacudida = nil
            }
        }
    }

    private func siguiente() {
        if ronda + 1 < rondas.count {
            ronda += 1
            prepararRonda()
        } else {
            terminar(ganadas, antes)
        }
    }
}
