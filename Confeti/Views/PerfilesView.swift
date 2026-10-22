import SwiftUI

/// Pantalla 1: "¿Quién va a jugar?". Cada niño entra tocando su piñata, sin leer ni escribir.
struct PerfilesView: View {
    @Environment(PerfilesStore.self) private var perfiles
    @ScaledMetric(relativeTo: .largeTitle) private var tamanoTitulo: CGFloat = 76
    @ScaledMetric(relativeTo: .largeTitle) private var tamanoRetrato: CGFloat = 140
    @State private var creando = false

    private let entrar: (Perfil) -> Void
    private let ajustes: () -> Void
    private let columnas = [GridItem(.adaptive(minimum: 230), spacing: 28)]

    init(entrar: @escaping (Perfil) -> Void, ajustes: @escaping () -> Void) {
        self.entrar = entrar
        self.ajustes = ajustes
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            FondoFiesta()

            VStack(spacing: 0) {
                Color.clear
                    .frame(height: FondoFiesta.altoBanderines)

                ScrollView {
                    VStack(spacing: 20) {
                        TituloFiesta(texto: "Confeti", tamano: tamanoTitulo)

                        Text("¿Quién va a jugar?")
                            .font(.system(.title, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.morado)
                            .calcomania()
                            .accessibilityAddTraits(.isHeader)

                        if perfiles.perfiles.isEmpty {
                            HStack(spacing: 24) {
                                RetratoPinata(imagen: Coleccion.iniciales[0].imagen, tamano: 150)
                                    .flotando()
                                GloboMensaje(texto: "¡Hola! Toca el + para crear tu jugador", icono: "hand.wave.fill", color: .rosa)
                            }
                            .padding(.vertical, 8)
                        }

                        LazyVGrid(columns: columnas, spacing: 32) {
                            ForEach(Array(perfiles.perfiles.enumerated()), id: \.element.id) { indice, perfil in
                                tarjeta(de: perfil, color: Color.titulo[indice % Color.titulo.count])
                            }
                            tarjetaNueva
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 60)
                    }
                    .padding(.top, 8)
                }
            }

            // Acceso discreto para el adulto: hay que mantenerlo presionado 2 segundos.
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundStyle(Color.morado.opacity(0.5))
                .frame(width: 64, height: 64)
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 2) { ajustes() }
                .padding(.top, FondoFiesta.altoBanderines + 10)
                .padding(.trailing, 12)
                .accessibilityLabel("Ajustes para adultos")
                .accessibilityHint("Mantén presionado dos segundos")
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { ajustes() }
        }
        .sheet(isPresented: $creando) {
            NuevoPerfilView(creado: entrar)
        }
        .onAppear {
            Voz.shared.anunciar(perfiles.perfiles.isEmpty
                ? "¡Hola! Toca el botón de nuevo jugador para empezar."
                : "¿Quién va a jugar? Toca tu piñata.")
        }
    }

    private func tarjeta(de perfil: Perfil, color: Color) -> some View {
        Button(action: { entrar(perfil) }) {
            VStack(spacing: 12) {
                RetratoPinata(imagen: Coleccion.pinata(id: perfil.pinataActiva).imagen, tamano: tamanoRetrato)
                    .flotando(amplitud: 6, duracion: 1.8, retraso: Double(perfil.nombre.count % 5) * 0.3)
                Text(perfil.nombre)
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Label("\(perfil.estrellas)", systemImage: "star.fill")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.morado)
            }
            .padding(.horizontal, 16)
            .padding(.top, 40)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .tarjetaFiesta(borde: color, conFlecos: true)
        }
        .buttonStyle(BotonTarjeta())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Jugador \(perfil.nombre)")
        .accessibilityValue("\(perfil.estrellas) estrellas")
        .accessibilityHint("Toca para entrar")
        .accessibilityAddTraits(.isButton)
    }

    private var tarjetaNueva: some View {
        Button(action: { creando = true }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle().fill(Color.amarillo)
                    Image(systemName: "plus")
                        .font(.system(size: tamanoRetrato * 0.4, weight: .heavy))
                        .foregroundStyle(Color.moradoOscuro)
                }
                .frame(width: tamanoRetrato * 1.12, height: tamanoRetrato * 1.12)
                Text("Nuevo jugador")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.morado)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(" ")
                    .font(.system(.headline, design: .rounded))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.top, 40)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 28).fill(Color.white.opacity(0.75))
                    RoundedRectangle(cornerRadius: 28).strokeBorder(Color.morado, style: StrokeStyle(lineWidth: 5, dash: [14, 10]))
                }
            }
        }
        .buttonStyle(BotonTarjeta())
        .accessibilityLabel("Nuevo jugador")
        .accessibilityHint("Crea un perfil para otro niño")
    }
}

/// Alta de un jugador: nombre y piñata favorita de las tres iniciales.
struct NuevoPerfilView: View {
    @Environment(PerfilesStore.self) private var perfiles
    @Environment(\.dismiss) private var dismiss
    @State private var nombre = ""
    @State private var pinata = Coleccion.iniciales[0].id
    @State private var intentoCrear = false
    @FocusState private var enfocado: Bool

    private let creado: (Perfil) -> Void

    init(creado: @escaping (Perfil) -> Void) {
        self.creado = creado
    }

    private var error: String? {
        ValidadorNombre.error(en: nombre, existentes: perfiles.perfiles.map(\.nombre))
    }

    private var mostrarError: Bool {
        error != nil && (intentoCrear || !nombre.isEmpty)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TituloFiesta(texto: "¿Cómo te llamas?", estilo: .largeTitle)
                    .frame(maxWidth: .infinity)

                TextField("Nombre", text: $nombre)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.moradoOscuro)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .focused($enfocado)
                    .submitLabel(.done)
                    .onSubmit(crear)
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 22).fill(Color.white))
                    .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.morado, lineWidth: mostrarError ? 4 : 2))
                    .accessibilityLabel("Nombre del jugador")

                if mostrarError, let error {
                    Label(error, systemImage: "exclamationmark.bubble.fill")
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.morado)
                        .accessibilityLabel("Aviso: \(error)")
                }

                Text("Elige tu piñata")
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(Color.morado)
                    .padding(.top, 8)

                HStack(spacing: 20) {
                    ForEach(Coleccion.iniciales) { opcion in
                        Button(action: { pinata = opcion.id }) {
                            VStack(spacing: 8) {
                                RetratoPinata(imagen: opcion.imagen, tamano: 110)
                                    .overlay {
                                        Circle()
                                            .strokeBorder(pinata == opcion.id ? Color.amarillo : Color.clear, lineWidth: 8)
                                            .padding(-8)
                                    }
                                Text(opcion.nombre)
                                    .font(.system(.headline, design: .rounded).weight(.bold))
                                    .foregroundStyle(Color.morado)
                                Image(systemName: pinata == opcion.id ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundStyle(pinata == opcion.id ? Color.verdeTexto : Color.morado.opacity(0.4))
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(BotonTarjeta())
                        .accessibilityLabel(opcion.nombre)
                        .accessibilityAddTraits(pinata == opcion.id ? [.isSelected] : [])
                    }
                }

                HStack {
                    Button(action: { dismiss() }) {
                        Label("Cancelar", systemImage: "xmark")
                    }
                    .buttonStyle(BotonCaramelo(color: .blanco))

                    Spacer()

                    Button(action: crear) {
                        Label("¡Listo!", systemImage: "checkmark")
                    }
                    .buttonStyle(BotonCaramelo(color: .verde))
                    .accessibilityHint("Crea el jugador y entra al juego")
                }
                .padding(.top, 12)
            }
            .padding(32)
        }
        .background(Color.crema.ignoresSafeArea())
        .onAppear { enfocado = true }
    }

    private func crear() {
        intentoCrear = true
        if let error {
            Voz.shared.anunciar(error)
            return
        }
        let perfil = perfiles.crear(nombre: nombre, pinata: pinata)
        dismiss()
        creado(perfil)
    }
}

#Preview("Elegir jugador") {
    NavigationStack {
        PerfilesView(entrar: { _ in }, ajustes: {})
    }
    .environment(PerfilesStore.vistaPrevia())
}

#Preview("Nuevo jugador") {
    NuevoPerfilView(creado: { _ in })
        .environment(PerfilesStore.vistaPrevia())
}
