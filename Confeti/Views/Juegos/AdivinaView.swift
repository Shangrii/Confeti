import SwiftUI

/// "¿Dónde está?": el niño lee (o escucha) una palabra y toca el dibujo que le corresponde.
struct AdivinaView: View {
    @Environment(PerfilesStore.self) private var perfiles
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var tamanoPalabra: CGFloat = 72

    private let terminar: (Int, Int) -> Void

    @State private var rondas: [PalabraJuego] = []
    @State private var ronda = 0
    @State private var opciones: [PalabraJuego] = []
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

    private var correcta: PalabraJuego? { rondas[safe: ronda] }
    private var pregunta: String { "¿Dónde está \(correcta?.definido ?? "")?" }

    var body: some View {
        ZStack {
            FondoFiesta()

            VStack(spacing: 24) {
                EncabezadoPantalla("¿Dónde está?") {
                    EstrellasJugador()
                }
                EncabezadoJuego(pregunta: pregunta, ronda: ronda, total: rondas.count)

                if let correcta {
                    Text(correcta.texto.uppercased())
                        .font(.system(size: tamanoPalabra, weight: .black, design: .rounded))
                        .tracking(8)
                        .foregroundStyle(Color.rosa)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .padding(.horizontal, 48)
                        .padding(.top, 44)
                        .padding(.bottom, 18)
                        .tarjetaFiesta(borde: .rosa, conFlecos: true)
                        .accessibilityLabel("Palabra: \(correcta.texto)")
                }

                HStack(spacing: 28) {
                    ForEach(opciones) { opcion in
                        tarjeta(de: opcion)
                    }
                }
                .frame(maxHeight: .infinity)

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

    private func tarjeta(de opcion: PalabraJuego) -> some View {
        let esCorrecta = acerto && opcion.id == correcta?.id
        let descartada = descartadas.contains(opcion.id)
        let borde: Color = esCorrecta ? .verdeTexto : (descartada ? .grisDesactivado : .morado)

        return Button(action: { elegir(opcion) }) {
            VStack(spacing: 8) {
                Image(opcion.imagen)
                    .resizable()
                    .scaledToFit()
                    .saturation(descartada ? 0 : 1)
                    .opacity(descartada ? 0.45 : 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                Group {
                    if esCorrecta {
                        Label(opcion.texto, systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Color.verdeTexto)
                    } else if descartada {
                        Text("Es \(opcion.conArticulo)")
                            .foregroundStyle(Color.grisDesactivado)
                    } else {
                        Text(" ")
                    }
                }
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .tarjetaFiesta(borde: borde, relleno: esCorrecta ? Color(hex: "DDF5E4") : .white)
            .scaleEffect(esCorrecta ? 1.05 : 1)
            .offset(x: sacudida == opcion.id ? 14 : 0)
        }
        .buttonStyle(BotonTarjeta())
        .disabled(acerto || descartada)
        .accessibilityLabel("Dibujo de \(opcion.conArticulo)")
        .accessibilityValue(esCorrecta ? "Correcto" : (descartada ? "Ya lo probaste" : ""))
    }

    private func preparar() {
        guard rondas.isEmpty else { return }
        antes = perfiles.activo?.estrellas ?? 0
        rondas = Array(ColeccionPalabras.catalogo.shuffled().prefix(Valores.rondasPorJuego))
        prepararRonda()
    }

    private func prepararRonda() {
        guard let correcta else { return }
        acerto = false
        errores = 0
        descartadas = []
        let otras = ColeccionPalabras.catalogo.filter { $0.id != correcta.id }.shuffled().prefix(2)
        opciones = ([correcta] + otras).shuffled()
        Voz.shared.anunciar("\(pregunta) Toca el dibujo.")
    }

    private func elegir(_ opcion: PalabraJuego) {
        guard !acerto, let correcta else { return }
        if opcion.id == correcta.id {
            let estrellas = estrellasPorErrores(errores)
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6)) {
                acerto = true
            }
            destello += 1
            ganadas += estrellas
            perfiles.sumarEstrellas(estrellas)
            Sonidos.shared.reproducir(.correcto)
            Voz.shared.anunciar("¡Sí! Ese es \(correcta.definido).")
        } else {
            errores += 1
            descartadas.insert(opcion.id)
            Sonidos.shared.reproducir(.casi)
            Voz.shared.anunciar("Ese es \(opcion.definido). Busca \(correcta.definido).")
            sacudir(opcion.id)
        }
    }

    private func sacudir(_ id: String) {
        guard !reduceMotion else { return }
        withAnimation(.spring(response: 0.12, dampingFraction: 0.2)) {
            sacudida = id
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
