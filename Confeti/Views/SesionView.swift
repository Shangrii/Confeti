import SwiftUI

/// Sesión de práctica de letras o números: tres trazos y luego la fiesta.
/// El nivel de ayuda de cada letra se ajusta solo según cómo le va al niño.
struct SesionView: View {
    @Environment(PerfilesStore.self) private var perfiles

    private let categoria: Categoria
    private let claves: [String]
    private let terminar: (Int, Int) -> Void

    @State private var indice = 0
    @State private var ganadas = 0
    @State private var antes: Int?

    init(categoria: Categoria, claves: [String], terminar: @escaping (Int, Int) -> Void) {
        self.categoria = categoria
        self.claves = claves
        self.terminar = terminar
    }

    private var items: [Trazo] {
        claves.compactMap { Trazo.buscar(clave: $0) }
    }

    var body: some View {
        let lista = items
        ZStack {
            FondoFiesta()
            VStack(spacing: 0) {
                EncabezadoPantalla(lista.isEmpty ? categoria.titulo : "\(categoria.titulo) · \(min(indice + 1, lista.count)) de \(lista.count)") {
                    EstrellasJugador()
                }
                if let trazo = lista[safe: indice] {
                    TrazoView(
                        trazo: trazo,
                        nivel: perfiles.activo?.nivel(de: trazo.clave) ?? .completa,
                        esUltimo: indice == lista.count - 1,
                        alEvaluar: { estrellas in registrar(estrellas, en: trazo) },
                        alTerminar: { avanzar(total: lista.count) }
                    )
                    .id(indice)
                }
            }
        }
        .onAppear {
            if antes == nil {
                antes = perfiles.activo?.estrellas ?? 0
            }
        }
    }

    /// Cada intento cuenta: las estrellas se guardan en cuanto se ganan y ajustan la ayuda de esa letra.
    private func registrar(_ estrellas: Int, en trazo: Trazo) {
        guard let id = perfiles.activoID else { return }
        ganadas += estrellas
        perfiles.actualizar(id) { perfil in
            perfil.registrar(estrellas: estrellas, en: trazo.clave)
            perfil.estrellas += estrellas
        }
    }

    private func avanzar(total: Int) {
        if indice + 1 < total {
            indice += 1
        } else {
            terminar(ganadas, antes ?? 0)
        }
    }
}
