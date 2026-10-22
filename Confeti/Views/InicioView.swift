import SwiftUI

/// Casa del jugador: su piñata, sus estrellas y qué tanto ha avanzado.
struct InicioView: View {
    @Environment(PerfilesStore.self) private var perfiles
    @AppStorage(Claves.umbrales) private var textoUmbrales = Valores.umbrales
    @ScaledMetric(relativeTo: .largeTitle) private var tamanoPinata: CGFloat = 250

    private let perfil: Perfil
    private let jugar: () -> Void
    private let album: () -> Void

    init(perfil: Perfil, jugar: @escaping () -> Void, album: @escaping () -> Void) {
        self.perfil = perfil
        self.jugar = jugar
        self.album = album
    }

    private var actual: Perfil { perfiles.activo ?? perfil }
    private var pinata: Pinata { Coleccion.pinata(id: actual.pinataActiva) }
    private var bienvenida: String {
        "¡Hola, \(actual.nombre)! Toca el botón de jugar para empezar la fiesta."
    }

    var body: some View {
        ZStack {
            FondoFiesta()

            VStack(spacing: 16) {
                EncabezadoPantalla("¡A la fiesta!") {
                    EstrellasJugador()
                }

                ViewThatFits {
                    HStack(spacing: 48) {
                        personaje
                        informacion
                    }
                    VStack(spacing: 24) {
                        personaje
                        informacion
                    }
                }
                .frame(maxHeight: .infinity)
                .padding(.horizontal, 32)

                HStack(spacing: 20) {
                    BotonEscuchar(texto: bienvenida, etiqueta: "Escuchar instrucciones")

                    Button(action: album) {
                        Label("Mis piñatas", systemImage: "square.grid.2x2.fill")
                    }
                    .buttonStyle(BotonCaramelo(color: .amarillo))
                    .accessibilityHint("Abre tu colección de piñatas")

                    Spacer()

                    Button(action: jugar) {
                        Label("¡A jugar!", systemImage: "play.fill")
                    }
                    .buttonStyle(BotonCaramelo(color: .rosa, grande: true))
                    .accessibilityHint("Elige si quieres aprender a trazar o jugar")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 28)
            }
        }
        .onAppear { Voz.shared.anunciar(bienvenida) }
    }

    private var personaje: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(Color.pastoOscuro.opacity(0.45))
                .frame(width: tamanoPinata * 1.1, height: tamanoPinata * 0.18)
                .offset(y: tamanoPinata * 0.08)
            RetratoPinata(imagen: pinata.imagen, tamano: tamanoPinata)
                .flotando(amplitud: 12, duracion: 1.7)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tu piñata: \(pinata.nombre)")
    }

    private var informacion: some View {
        VStack(alignment: .leading, spacing: 18) {
            TituloFiesta(texto: "¡Hola, \(actual.nombre)!")

            VStack(alignment: .leading, spacing: 14) {
                avance(titulo: "Letras", icono: "textformat.abc", hechos: actual.dominados(en: .letras), total: Categoria.letras.items.count)
                avance(titulo: "Números", icono: "textformat.123", hechos: actual.dominados(en: .numeros), total: Categoria.numeros.items.count)
            }
            .padding(20)
            .frame(maxWidth: 420)
            .tarjetaFiesta(borde: .morado, radio: 24)

            if let siguiente = Coleccion.siguiente(con: actual.estrellas, umbrales: Coleccion.umbrales(desde: textoUmbrales)) {
                HStack(spacing: 14) {
                    RetratoPinata(imagen: siguiente.pinata.imagen, tamano: 56, gris: true)
                    Text("Te faltan \(siguiente.faltan) estrellas para ganar a \(siguiente.pinata.nombre)")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.morado)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: 420, alignment: .leading)
                .tarjetaFiesta(borde: .amarilloOscuro, relleno: Color(hex: "FFF4CF"), radio: 22)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func avance(titulo: String, icono: String, hechos: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(titulo, systemImage: icono)
                Spacer()
                Text("\(hechos) de \(total)")
                    .monospacedDigit()
            }
            .font(.system(.headline, design: .rounded).weight(.heavy))
            .foregroundStyle(Color.morado)
            BarraAvance(valor: Double(hechos) / Double(max(total, 1)))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(titulo): \(hechos) de \(total) con tres estrellas")
    }
}

/// Primera decisión: aprender a trazar o jugar. Sólo dos opciones grandes.
struct MapaView: View {
    private let aprender: () -> Void
    private let jugar: () -> Void

    init(aprender: @escaping () -> Void, jugar: @escaping () -> Void) {
        self.aprender = aprender
        self.jugar = jugar
    }

    var body: some View {
        ZStack {
            FondoFiesta()
            VStack(spacing: 8) {
                EncabezadoPantalla("¿Qué hacemos hoy?") {
                    EstrellasJugador()
                }
                HStack(spacing: 40) {
                    TarjetaJuego(titulo: "Aprender", subtitulo: "Traza letras, números y tu nombre", color: .morado, accion: aprender) {
                        MedallonBlanco {
                            Text("ABC")
                                .font(.system(size: 200, weight: .black, design: .rounded))
                                .minimumScaleFactor(0.1)
                                .foregroundStyle(Color.morado)
                                .flotando(amplitud: 6, duracion: 1.5)
                        }
                    }
                    TarjetaJuego(titulo: "Jugar", subtitulo: "Retos con dibujos y palabras", color: .rosa, accion: jugar) {
                        MedallonBlanco {
                            PinataEstrella()
                                .flotando(amplitud: 10, duracion: 1.4)
                        }
                    }
                }
                .padding(.horizontal, 48)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
        }
        .onAppear {
            Voz.shared.anunciar("Toca aprender para trazar letras, o jugar para retos divertidos.")
        }
    }
}

/// Aprender: letras, números o el nombre del niño.
struct AprenderView: View {
    @Environment(PerfilesStore.self) private var perfiles
    private let elegir: (Categoria) -> Void
    private let nombre: () -> Void

    init(elegir: @escaping (Categoria) -> Void, nombre: @escaping () -> Void) {
        self.elegir = elegir
        self.nombre = nombre
    }

    private var iniciales: String {
        let letras = Nombre.secuencia(de: perfiles.activo?.nombre ?? "")
        return letras.prefix(3).joined()
    }

    var body: some View {
        ZStack {
            FondoFiesta()
            VStack(spacing: 8) {
                EncabezadoPantalla("Aprender a trazar") {
                    EstrellasJugador()
                }
                HStack(spacing: 32) {
                    TarjetaJuego(titulo: "Letras", subtitulo: "De la A a la Z", color: .morado, accion: { elegir(.letras) }) {
                        MedallonBlanco { textoMedallon("ABC", color: .morado) }
                    }
                    TarjetaJuego(titulo: "Números", subtitulo: "Del 0 al 9", color: .turquesa, accion: { elegir(.numeros) }) {
                        MedallonBlanco { textoMedallon("123", color: .turquesa) }
                    }
                    TarjetaJuego(titulo: "Mi nombre", subtitulo: "Aprende a escribirlo", color: .naranja, accion: nombre) {
                        MedallonBlanco { textoMedallon(iniciales.isEmpty ? "ABC" : iniciales, color: .naranja) }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            Voz.shared.anunciar("¿Qué quieres aprender? Letras, números o tu nombre.")
        }
    }

    private func textoMedallon(_ texto: String, color: Color) -> some View {
        Text(texto)
            .font(.system(size: 200, weight: .black, design: .rounded))
            .minimumScaleFactor(0.1)
            .lineLimit(1)
            .foregroundStyle(color)
            .flotando(amplitud: 6, duracion: 1.5, retraso: Double(texto.count) * 0.2)
    }
}

/// Los cuatro juegos de palabras y números.
struct JuegosView: View {
    private let elegir: (ModoJuego) -> Void
    private let columnas = [GridItem(.flexible(), spacing: 32), GridItem(.flexible(), spacing: 32)]

    init(elegir: @escaping (ModoJuego) -> Void) {
        self.elegir = elegir
    }

    var body: some View {
        ZStack {
            FondoFiesta()
            VStack(spacing: 0) {
                EncabezadoPantalla("Juegos") {
                    EstrellasJugador()
                }
                GeometryReader { geo in
                    let alto = max((geo.size.height - 32 - 80) / 2, 180)
                    LazyVGrid(columns: columnas, spacing: 32) {
                        tarjeta(.adivina, titulo: "¿Dónde está?", subtitulo: "Encuentra el dibujo", color: .rosa, imagen: "gato", texto: nil)
                            .frame(height: alto)
                        tarjeta(.primeraLetra, titulo: "¿Con qué empieza?", subtitulo: "Busca la primera letra", color: .azul, imagen: "manzana", texto: "M")
                            .frame(height: alto)
                        tarjeta(.escribe, titulo: "Escribe", subtitulo: "Traza el nombre del dibujo", color: .turquesa, imagen: "taco", texto: nil)
                            .frame(height: alto)
                        tarjeta(.cuenta, titulo: "Cuenta y traza", subtitulo: "Cuenta y escribe el número", color: .naranja, imagen: "galleta", texto: "3")
                            .frame(height: alto)
                    }
                    .padding(40)
                }
            }
        }
        .onAppear {
            Voz.shared.anunciar("Elige un juego.")
        }
    }

    private func tarjeta(_ modo: ModoJuego, titulo: String, subtitulo: String, color: ColorCaramelo, imagen: String, texto: String?) -> some View {
        TarjetaJuego(titulo: titulo, subtitulo: subtitulo, color: color, accion: { elegir(modo) }) {
            MedallonBlanco {
                ZStack(alignment: .bottomTrailing) {
                    Image(imagen)
                        .resizable()
                        .scaledToFit()
                        .flotando(amplitud: 6, duracion: 1.6, retraso: Double(imagen.count % 4) * 0.25)
                    if let texto {
                        Text(texto)
                            .font(.system(.largeTitle, design: .rounded).weight(.black))
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(Circle().fill(color.base))
                            .overlay(Circle().strokeBorder(Color.white, lineWidth: 4))
                    }
                }
            }
        }
    }
}

#Preview("Inicio") {
    NavigationStack {
        InicioView(perfil: Perfil(nombre: "Ana", pinata: 5), jugar: {}, album: {})
    }
    .environment(PerfilesStore.vistaPrevia())
}

#Preview("Inicio · texto grande") {
    NavigationStack {
        InicioView(perfil: Perfil(nombre: "Ana", pinata: 5), jugar: {}, album: {})
    }
    .environment(PerfilesStore.vistaPrevia())
    .environment(\.dynamicTypeSize, .accessibility2)
}

#Preview("Mapa") {
    MapaView(aprender: {}, jugar: {})
        .environment(PerfilesStore.vistaPrevia())
}

#Preview("Juegos") {
    JuegosView(elegir: { _ in })
        .environment(PerfilesStore.vistaPrevia())
}
