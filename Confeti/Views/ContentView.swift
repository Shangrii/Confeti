import SwiftUI

enum ModoJuego: String, CaseIterable, Identifiable, Hashable {
    case adivina
    case primeraLetra
    case escribe
    case cuenta

    var id: String { rawValue }
}

/// Desde dónde se llegó a una sesión, para que "Seguir jugando" regrese ahí.
enum Origen: Hashable {
    case aprender
    case juegos
}

enum Pantalla: Hashable {
    case inicio
    case mapa
    case aprender
    case juegos
    case tablero(Categoria)
    case sesion(Categoria, [String])
    case nombre
    case juego(ModoJuego)
    case cierre(ganadas: Int, antes: Int, origen: Origen)
    case album
}

struct ContentView: View {
    @Environment(PerfilesStore.self) private var perfiles
    @State private var ruta: [Pantalla] = []
    @State private var mostrarAjustes = false

    var body: some View {
        NavigationStack(path: $ruta) {
            PerfilesView(
                entrar: { perfil in
                    perfiles.activoID = perfil.id
                    ruta = [.inicio]
                },
                ajustes: { mostrarAjustes = true }
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Pantalla.self) { pantalla in
                destino(pantalla)
            }
        }
        .statusBarHidden(true)
        .onAppear { Musica.shared.actualizar() }
        .sheet(isPresented: $mostrarAjustes) {
            AjustesView()
        }
    }

    private func terminar(origen: Origen) -> (Int, Int) -> Void {
        { ganadas, antes in
            ruta.append(.cierre(ganadas: ganadas, antes: antes, origen: origen))
        }
    }

    @ViewBuilder
    private func destino(_ pantalla: Pantalla) -> some View {
        if let perfil = perfiles.activo {
            switch pantalla {
            case .inicio:
                InicioView(perfil: perfil, jugar: { ruta.append(.mapa) }, album: { ruta.append(.album) })
                    .toolbar(.hidden, for: .navigationBar)

            case .mapa:
                MapaView(aprender: { ruta.append(.aprender) }, jugar: { ruta.append(.juegos) })
                    .toolbar(.hidden, for: .navigationBar)

            case .aprender:
                AprenderView(
                    elegir: { categoria in ruta.append(.tablero(categoria)) },
                    nombre: { ruta.append(.nombre) }
                )
                .toolbar(.hidden, for: .navigationBar)

            case .juegos:
                JuegosView(elegir: { modo in ruta.append(.juego(modo)) })
                    .toolbar(.hidden, for: .navigationBar)

            case .tablero(let categoria):
                TableroView(categoria: categoria, empezar: { claves in
                    ruta.append(.sesion(categoria, claves))
                })
                .toolbar(.hidden, for: .navigationBar)

            case .sesion(let categoria, let claves):
                SesionView(categoria: categoria, claves: claves, terminar: terminar(origen: .aprender))
                    .toolbar(.hidden, for: .navigationBar)

            case .nombre:
                NombreSesionView(terminar: terminar(origen: .aprender))
                    .toolbar(.hidden, for: .navigationBar)

            case .juego(let modo):
                destinoJuego(modo)
                    .toolbar(.hidden, for: .navigationBar)

            case .cierre(let ganadas, let antes, let origen):
                CierreView(
                    ganadas: ganadas,
                    antes: antes,
                    inicio: { ruta = [.inicio] },
                    album: { ruta.append(.album) },
                    seguir: { ruta = [.inicio, .mapa, origen == .aprender ? .aprender : .juegos] }
                )
                .toolbar(.hidden, for: .navigationBar)

            case .album:
                AlbumView()
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }

    @ViewBuilder
    private func destinoJuego(_ modo: ModoJuego) -> some View {
        switch modo {
        case .adivina:
            AdivinaView(terminar: terminar(origen: .juegos))
        case .primeraLetra:
            PrimeraLetraView(terminar: terminar(origen: .juegos))
        case .escribe:
            EscribePalabraView(terminar: terminar(origen: .juegos))
        case .cuenta:
            CuentaView(terminar: terminar(origen: .juegos))
        }
    }
}

#Preview {
    ContentView()
        .environment(PerfilesStore.vistaPrevia())
}
