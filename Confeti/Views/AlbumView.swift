import SwiftUI

/// Colección de piñatas del jugador: a color las que ya ganó, en gris con candado las que faltan.
/// Nunca se pierde nada: no hay forma de volver a bloquear un personaje.
struct AlbumView: View {
    @Environment(PerfilesStore.self) private var perfiles
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(Claves.umbrales) private var textoUmbrales = Valores.umbrales
    @ScaledMetric(relativeTo: .largeTitle) private var tamanoRetrato: CGFloat = 130
    @State private var elegida: Int?

    private var columnas: [GridItem] {
        [GridItem(.adaptive(minimum: tamanoRetrato * 1.5), spacing: 24)]
    }

    var body: some View {
        let umbrales = Coleccion.umbrales(desde: textoUmbrales)
        let estrellas = perfiles.activo?.estrellas ?? 0
        let activa = perfiles.activo?.pinataActiva

        ZStack {
            FondoFiesta()

            VStack(spacing: 0) {
                EncabezadoPantalla("Mis piñatas") {
                    EstrellasJugador()
                }

                ScrollView {
                    VStack(spacing: 24) {
                        encabezado(estrellas: estrellas, umbrales: umbrales)

                        LazyVGrid(columns: columnas, spacing: 28) {
                            ForEach(Array(Coleccion.pinatas.enumerated()), id: \.element.id) { indice, pinata in
                                let necesarias = Coleccion.estrellasNecesarias(indice: indice, umbrales: umbrales)
                                tarjeta(pinata, faltan: max(necesarias - estrellas, 0), activa: pinata.id == activa)
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            Voz.shared.anunciar("Estas son tus piñatas. Toca una de color para que juegue contigo.")
        }
    }

    private func encabezado(estrellas: Int, umbrales: [Int]) -> some View {
        HStack(spacing: 24) {
            Image(systemName: "gift.fill")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Color.rosa)
                .accessibilityHidden(true)
            Text("\(Coleccion.desbloqueadas(con: estrellas, umbrales: umbrales)) de \(Coleccion.pinatas.count) piñatas")
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(Color.morado)
            Spacer()
            if let siguiente = Coleccion.siguiente(con: estrellas, umbrales: umbrales) {
                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(siguiente.pinata.nombre): faltan \(siguiente.faltan)")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.morado)
                    BarraAvance(valor: siguiente.avance)
                        .frame(width: 240)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Te faltan \(siguiente.faltan) estrellas para ganar a \(siguiente.pinata.nombre)")
            }
        }
        .padding(20)
        .tarjetaFiesta(borde: .morado, radio: 28)
    }

    private func tarjeta(_ pinata: Pinata, faltan: Int, activa: Bool) -> some View {
        let desbloqueada = faltan == 0
        let borde: Color = activa ? .amarilloOscuro : (desbloqueada ? .morado : .grisDesactivado)

        return Button(action: { tocar(pinata, faltan: faltan) }) {
            VStack(spacing: 10) {
                ZStack {
                    RetratoPinata(imagen: pinata.imagen, tamano: tamanoRetrato, gris: !desbloqueada)
                    if !desbloqueada {
                        Image(systemName: "lock.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(Circle().fill(Color.morado))
                    }
                }
                .scaleEffect(elegida == pinata.id ? 1.08 : 1)

                Text(pinata.nombre)
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .foregroundStyle(desbloqueada ? Color.morado : Color.grisDesactivado)

                Group {
                    if activa {
                        Label("¡Juega contigo!", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Color.verdeTexto)
                    } else if desbloqueada {
                        Label("Toca para elegir", systemImage: "hand.tap.fill")
                            .foregroundStyle(Color.morado)
                    } else {
                        Label("Faltan \(faltan)", systemImage: "star")
                            .foregroundStyle(Color.morado)
                    }
                }
                .font(.system(.headline, design: .rounded).weight(.bold))
            }
            .padding(.horizontal, 12)
            .padding(.top, 40)
            .padding(.bottom, 18)
            .frame(maxWidth: .infinity)
            .tarjetaFiesta(
                borde: borde,
                relleno: activa ? Color(hex: "FFF4CF") : (desbloqueada ? .papel : Color(hex: "F1EEF4")),
                conFlecos: desbloqueada
            )
        }
        .buttonStyle(BotonTarjeta())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(pinata.nombre)
        .accessibilityValue(activa ? "Juega contigo" : (desbloqueada ? "Desbloqueada" : "Bloqueada, faltan \(faltan) estrellas"))
        .accessibilityAddTraits(.isButton)
    }

    private func tocar(_ pinata: Pinata, faltan: Int) {
        guard faltan == 0 else {
            Sonidos.shared.reproducir(.casi)
            Voz.shared.anunciar("Te faltan \(faltan) estrellas para ganar a \(pinata.nombre). ¡Sigue jugando!")
            return
        }
        if let id = perfiles.activoID {
            perfiles.actualizar(id) { $0.pinataActiva = pinata.id }
        }
        Sonidos.shared.reproducir(.correcto)
        Voz.shared.anunciar("¡\(pinata.nombre) va a jugar contigo!")
        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.4)) {
            elegida = pinata.id
        }
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.6)) {
                elegida = nil
            }
        }
    }
}

#Preview {
    NavigationStack {
        AlbumView()
    }
    .environment(PerfilesStore.vistaPrevia())
}
