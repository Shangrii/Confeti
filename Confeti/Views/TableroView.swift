import SwiftUI

/// Todas las letras (o números) con las estrellas que el niño ya ganó en cada una.
/// Tocar una ficha arma una sesión con esa y dos que necesitan práctica.
struct TableroView: View {
    @Environment(PerfilesStore.self) private var perfiles
    @ScaledMetric(relativeTo: .largeTitle) private var tamanoFicha: CGFloat = 112

    private let categoria: Categoria
    private let empezar: ([String]) -> Void

    init(categoria: Categoria, empezar: @escaping ([String]) -> Void) {
        self.categoria = categoria
        self.empezar = empezar
    }

    private var columnas: [GridItem] {
        [GridItem(.adaptive(minimum: tamanoFicha), spacing: 18)]
    }

    var body: some View {
        let perfil = perfiles.activo
        let dominados = perfil?.dominados(en: categoria) ?? 0
        let total = categoria.items.count

        ZStack {
            FondoFiesta()

            VStack(spacing: 20) {
                EncabezadoPantalla(categoria.titulo) {
                    EstrellasJugador()
                }

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Con 3 estrellas: \(dominados) de \(total)")
                            .font(.system(.title2, design: .rounded).weight(.heavy))
                            .foregroundStyle(Color.morado)
                        BarraAvance(valor: Double(dominados) / Double(max(total, 1)))
                            .frame(maxWidth: 420)
                    }
                    .accessibilityElement(children: .combine)

                    Spacer()

                    BotonEscuchar(texto: "Toca una \(categoria == .letras ? "letra" : "ficha") para practicarla, o toca sorpresa.")

                    Button {
                        if let perfil {
                            empezar(perfil.sesion(empezandoCon: nil, en: categoria))
                        }
                    } label: {
                        Label("¡Sorpresa!", systemImage: "gift.fill")
                    }
                    .buttonStyle(BotonCaramelo(color: .rosa))
                    .accessibilityHint("Practica tres al azar, empezando por las que más te cuestan")
                }
                .padding(20)
                .tarjetaFiesta(borde: .morado, radio: 28)
                .padding(.horizontal, 28)

                ScrollView {
                    LazyVGrid(columns: columnas, spacing: 22) {
                        ForEach(Array(categoria.items.enumerated()), id: \.element.id) { indice, trazo in
                            ficha(trazo, mejor: perfil?.mejor(de: trazo.clave) ?? 0, color: Color.titulo[indice % Color.titulo.count])
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 32)
                }
            }
        }
        .onAppear {
            Voz.shared.anunciar("Toca una \(categoria == .letras ? "letra" : "ficha") para practicarla.")
        }
    }

    private func ficha(_ trazo: Trazo, mejor: Int, color: Color) -> some View {
        Button {
            if let perfil = perfiles.activo {
                empezar(perfil.sesion(empezandoCon: trazo, en: categoria))
            }
        } label: {
            VStack(spacing: 4) {
                Text(trazo.id)
                    .font(.system(size: tamanoFicha * 0.5, weight: .black, design: .rounded))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                FilaEstrellas(cantidad: mejor, tamano: .headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: tamanoFicha * 1.15)
            .tarjetaFiesta(
                borde: mejor == 3 ? .amarilloOscuro : color,
                relleno: mejor == 3 ? Color(hex: "FFF4CF") : .papel,
                radio: 24
            )
            .overlay(alignment: .topTrailing) {
                if mejor == 3 {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundStyle(Color.amarilloOscuro)
                        .padding(8)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(BotonTarjeta())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(trazo.nombreHablado)
        .accessibilityValue(mejor == 0 ? "Sin practicar" : "Mejor resultado: \(mejor) de 3 estrellas")
        .accessibilityHint("Toca para practicar")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    NavigationStack {
        TableroView(categoria: .letras, empezar: { _ in })
    }
    .environment(PerfilesStore.vistaPrevia())
}
