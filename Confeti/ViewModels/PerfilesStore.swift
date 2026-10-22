import Foundation
import Observation

/// Perfiles de los niños que usan el iPad. Se guardan como JSON en el dispositivo,
/// así el avance de cada niño sobrevive al cerrar y abrir la app.
@MainActor
@Observable
final class PerfilesStore {
    private(set) var perfiles: [Perfil] = []
    var activoID: UUID?

    private let archivo: URL
    private let colaGuardado = DispatchQueue(label: "confeti.guardado", qos: .utility)

    init(archivo: URL = URL.documentsDirectory.appending(path: "perfiles.json")) {
        self.archivo = archivo
        cargar()
    }

    var activo: Perfil? {
        perfiles.first { $0.id == activoID }
    }

    @discardableResult
    func crear(nombre: String, pinata: Int) -> Perfil {
        let perfil = Perfil(nombre: ValidadorNombre.limpiar(nombre), pinata: pinata)
        perfiles.append(perfil)
        guardar()
        return perfil
    }

    func actualizar(_ id: UUID, _ cambio: (inout Perfil) -> Void) {
        guard let indice = perfiles.firstIndex(where: { $0.id == id }) else { return }
        cambio(&perfiles[indice])
        guardar()
    }

    /// Suma estrellas al jugador activo en cuanto las gana, para que nunca se pierdan
    /// aunque el niño salga a mitad de una sesión.
    func sumarEstrellas(_ cantidad: Int) {
        guard let id = activoID, cantidad > 0 else { return }
        actualizar(id) { $0.estrellas += cantidad }
    }

    func borrar(_ id: UUID) {
        perfiles.removeAll { $0.id == id }
        if activoID == id { activoID = nil }
        guardar()
    }

    private func cargar() {
        guard let datos = try? Data(contentsOf: archivo),
              let lista = try? JSONDecoder().decode([Perfil].self, from: datos) else { return }
        perfiles = lista
    }

    /// La escritura al disco va en una cola de fondo para no detener la interfaz.
    /// Es una cola serial, así que los guardados nunca se adelantan entre sí.
    private func guardar() {
        guard let datos = try? JSONEncoder().encode(perfiles) else { return }
        let destino = archivo
        colaGuardado.async {
            try? datos.write(to: destino, options: .atomic)
        }
    }
}

extension PerfilesStore {
    static func vistaPrevia() -> PerfilesStore {
        let store = PerfilesStore(archivo: URL.temporaryDirectory.appending(path: "perfiles-preview.json"))
        if store.perfiles.isEmpty {
            store.crear(nombre: "Ana", pinata: 5)
            store.crear(nombre: "Luis", pinata: 9)
        }
        store.activoID = store.perfiles.first?.id
        return store
    }
}
