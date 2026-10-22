import SwiftUI

/// "Escribe": el niño ve un dibujo y traza, letra por letra, la palabra que lo nombra.
/// Cada letra usa el nivel de ayuda que el niño ya tiene en esa letra.
struct EscribePalabraView: View {
    @Environment(PerfilesStore.self) private var perfiles
    @ScaledMetric(relativeTo: .largeTitle) private var tamanoDibujo: CGFloat = 320
    @ScaledMetric(relativeTo: .largeTitle) private var tamanoPalabra: CGFloat = 64

    private let terminar: (Int, Int) -> Void

    @State private var palabra: PalabraJuego?
    @State private var indiceLetra = 0
    @State private var presentando = true
    @State private var ganadas = 0
    @State private var antes = 0

    init(terminar: @escaping (Int, Int) -> Void) {
        self.terminar = terminar
    }

    private var letras: [String] {
        Nombre.secuencia(de: palabra?.texto ?? "")
    }

    var body: some View {
        ZStack {
            FondoFiesta()

            VStack(spacing: 0) {
                EncabezadoPantalla(presentando ? "Escribe" : "Escribe · Letra \(indiceLetra + 1) de \(letras.count)") {
                    EstrellasJugador()
                }
                if let palabra {
                    if presentando {
                        presentacion(palabra)
                    } else {
                        juego(palabra)
                    }
                }
            }
        }
        .onAppear(perform: preparar)
    }

    private func presentacion(_ palabra: PalabraJuego) -> some View {
        VStack(spacing: 24) {
            Spacer()
            TituloFiesta(texto: "¡Vamos a escribir!")
            Image(palabra.imagen)
                .resizable()
                .scaledToFit()
                .frame(width: tamanoDibujo, height: tamanoDibujo)
                .padding(20)
                .padding(.top, 24)
                .tarjetaFiesta(borde: .turquesa, relleno: .white, radio: 36, conFlecos: true)
                .accessibilityLabel("Dibujo de \(palabra.conArticulo)")
            Text(palabra.texto.uppercased())
                .font(.system(size: tamanoPalabra, weight: .black, design: .rounded))
                .tracking(10)
                .foregroundStyle(Color.turquesa)
                .calcomania()
            Button(action: empezar) {
                Label("¡Empezar a trazar!", systemImage: "pencil.and.outline")
            }
            .buttonStyle(BotonCaramelo(color: .turquesa, grande: true))
            Spacer()
        }
        .padding(32)
        .transition(.opacity)
    }

    private func juego(_ palabra: PalabraJuego) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 20) {
                Image(palabra.imagen)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 96, height: 96)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.white))
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.turquesa, lineWidth: 4))
                    .accessibilityLabel("Dibujo de \(palabra.conArticulo)")
                FilaFichas(letras: letras) { i in
                    i < indiceLetra ? .hecha : (i == indiceLetra ? .actual : .pendiente)
                }
                Spacer()
            }
            .padding(.horizontal, 24)

            if let letra = letras[safe: indiceLetra], let trazo = Trazo.letra(letra) {
                TrazoView(
                    trazo: trazo,
                    nivel: perfiles.activo?.nivel(de: trazo.clave) ?? .completa,
                    esUltimo: indiceLetra == letras.count - 1,
                    minimoEstrellas: 2,
                    anuncioPrevio: indiceLetra == 0 ? "\(palabra.texto) empieza con \(letra)." : "Ahora la \(letra).",
                    alEvaluar: { estrellas in guardar(estrellas, en: trazo) },
                    alTerminar: avanzar
                )
                .id(indiceLetra)
            }
        }
        .transition(.opacity)
    }

    private func preparar() {
        guard palabra == nil else { return }
        antes = perfiles.activo?.estrellas ?? 0
        palabra = ColeccionPalabras.catalogo.randomElement()
        if let palabra {
            Voz.shared.anunciar("Mira el dibujo. Vamos a escribir \(palabra.texto). Toca el botón para empezar.")
        }
    }

    private func empezar() {
        withAnimation(.easeOut(duration: 0.25)) {
            presentando = false
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

    private func avanzar() {
        if indiceLetra + 1 < letras.count {
            indiceLetra += 1
        } else {
            terminar(ganadas, antes)
        }
    }
}
