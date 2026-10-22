import SwiftUI

/// Modo "Mi nombre". Cada sesión enseña hasta dos letras del nombre en tres pasos
/// (con guía, sólo el inicio y sin guía). Cuando ya las domina todas, el reto es escribir el nombre completo sin ayuda.
struct NombreSesionView: View {
    @Environment(PerfilesStore.self) private var perfiles

    private enum Paso: Hashable {
        case aprender(letra: String, nivel: NivelAyuda)
        case escribir(indice: Int)
    }

    private let terminar: (Int, Int) -> Void

    @State private var pasos: [Paso] = []
    @State private var indice = 0
    @State private var escribiendoNombre = false
    @State private var mostrarIntro = true
    @State private var ganadas = 0
    @State private var antes = 0

    init(terminar: @escaping (Int, Int) -> Void) {
        self.terminar = terminar
    }

    private var nombre: String { perfiles.activo?.nombre ?? "" }
    private var secuencia: [String] { Nombre.secuencia(de: nombre) }
    private var unicas: [String] { Nombre.letras(de: nombre) }
    private var dominadas: Set<String> { perfiles.activo?.letrasNombre ?? [] }

    var body: some View {
        ZStack {
            FondoFiesta()

            VStack(spacing: 0) {
                EncabezadoPantalla(titulo) {
                    EstrellasJugador()
                }

                if secuencia.isEmpty {
                    Spacer()
                    sinLetras
                    Spacer()
                } else if mostrarIntro {
                    intro
                } else if let paso = pasos[safe: indice] {
                    encabezado(paso)
                        .padding(.horizontal, 24)
                    vistaTrazo(paso)
                }
            }
        }
        .onAppear(perform: preparar)
    }

    // MARK: - Pantallas

    private var intro: some View {
        VStack(spacing: 24) {
            Spacer()
            TituloFiesta(texto: escribiendoNombre ? "¡Escribe tu nombre!" : "Las letras de \(nombre)")

            FilaFichas(letras: escribiendoNombre ? secuencia : unicas) { i in
                if escribiendoNombre { return .hecha }
                let letra = unicas[i]
                if dominadas.contains(letra) { return .hecha }
                return letrasDeHoy.contains(letra) ? .actual : .pendiente
            }
            .frame(maxWidth: 760)

            Text(textoIntro)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Color.morado)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 640)
                .padding(24)
                .tarjetaFiesta(borde: .naranja, radio: 28)

            Button(action: empezar) {
                Label(escribiendoNombre ? "¡Escribir mi nombre!" : "¡Empezar!", systemImage: "pencil.and.outline")
            }
            .buttonStyle(BotonCaramelo(color: .naranja, grande: true))
            Spacer()
        }
        .padding(32)
    }

    private var sinLetras: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 72))
                .foregroundStyle(Color.morado)
            Text("Este nombre no tiene letras para trazar.")
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(Color.morado)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .tarjetaFiesta()
    }

    private func encabezado(_ paso: Paso) -> some View {
        HStack(spacing: 16) {
            switch paso {
            case .aprender(let letra, let nivel):
                FilaFichas(letras: unicas) { i in
                    let l = unicas[i]
                    if l == letra { return .actual }
                    return dominadas.contains(l) ? .hecha : .pendiente
                }
                Spacer()
                PasosLetra(nivel: nivel, letra: letra)
            case .escribir(let posicion):
                FilaFichas(letras: secuencia) { i in
                    i < posicion ? .hecha : (i == posicion ? .actual : .pendiente)
                }
                Spacer()
                Label("Reto final · ¡Sin guía!", systemImage: "sparkles")
                    .font(.system(.headline, design: .rounded).weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.naranja))
            }
        }
    }

    @ViewBuilder
    private func vistaTrazo(_ paso: Paso) -> some View {
        switch paso {
        case .aprender(let letra, let nivel):
            if let trazo = Trazo.letra(letra) {
                TrazoView(
                    trazo: trazo,
                    nivel: nivel,
                    esUltimo: indice == pasos.count - 1,
                    minimoEstrellas: 2,
                    anuncioPrevio: anuncio(para: paso),
                    alEvaluar: { estrellas in guardar(estrellas, en: trazo) },
                    alTerminar: avanzar
                )
                .id(indice)
            }
        case .escribir(let posicion):
            if let letra = secuencia[safe: posicion], let trazo = Trazo.letra(letra) {
                TrazoView(
                    trazo: trazo,
                    nivel: .ninguna,
                    esUltimo: indice == pasos.count - 1,
                    minimoEstrellas: 2,
                    anuncioPrevio: anuncio(para: paso),
                    alEvaluar: { estrellas in guardar(estrellas, en: trazo) },
                    alTerminar: avanzar
                )
                .id(indice)
            }
        }
    }

    // MARK: - Lógica

    private var letrasDeHoy: [String] {
        pasos.compactMap { paso in
            if case .aprender(let letra, .completa) = paso { return letra }
            return nil
        }
    }

    private var textoIntro: String {
        if escribiendoNombre {
            return "¡Ya conoces todas las letras de tu nombre! Ahora escríbelo completo tú solito, sin guía."
        }
        let hoy = letrasDeHoy.joined(separator: " y ")
        return "Hoy vamos a aprender la \(hoy). Cada letra tiene tres pasos: con guía, sólo con el punto y tú solito."
    }

    private var titulo: String {
        guard !mostrarIntro, let paso = pasos[safe: indice] else { return "Mi nombre" }
        switch paso {
        case .aprender(let letra, _): return "Mi nombre · Letra \(letra)"
        case .escribir(let posicion): return "Mi nombre · Letra \(posicion + 1) de \(secuencia.count)"
        }
    }

    private func preparar() {
        guard pasos.isEmpty else { return }
        antes = perfiles.activo?.estrellas ?? 0
        let pendientes = unicas.filter { !dominadas.contains($0) && Trazo.letra($0) != nil }

        if pendientes.isEmpty {
            escribiendoNombre = true
            pasos = secuencia.indices
                .filter { Trazo.letra(secuencia[$0]) != nil }
                .map { Paso.escribir(indice: $0) }
        } else {
            escribiendoNombre = false
            var nuevos: [Paso] = []
            for letra in pendientes.prefix(Valores.letrasNombrePorSesion) {
                for nivel in [NivelAyuda.completa, .inicio, .ninguna] {
                    nuevos.append(.aprender(letra: letra, nivel: nivel))
                }
            }
            pasos = nuevos
        }
        Voz.shared.anunciar(textoIntro)
    }

    private func empezar() {
        withAnimation(.easeOut(duration: 0.25)) {
            mostrarIntro = false
        }
    }

    private func anuncio(para paso: Paso) -> String {
        switch paso {
        case .aprender(let letra, let nivel):
            return "Letra \(letra), paso \(nivel == .completa ? 1 : (nivel == .inicio ? 2 : 3)) de 3."
        case .escribir(let posicion):
            return posicion == 0 ? "Empieza tu nombre con la \(secuencia[posicion])." : "Ahora la \(secuencia[posicion])."
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
        guard let id = perfiles.activoID else { return }
        if let paso = pasos[safe: indice], case .aprender(let letra, .ninguna) = paso {
            perfiles.actualizar(id) { $0.letrasNombre.insert(letra) }
        }

        if indice + 1 < pasos.count {
            indice += 1
            return
        }
        if escribiendoNombre {
            perfiles.actualizar(id) { $0.nombreEscrito += 1 }
        }
        terminar(ganadas, antes)
    }
}

/// Los tres pasos para aprender una letra, con el actual resaltado.
private struct PasosLetra: View {
    let nivel: NivelAyuda
    let letra: String

    private let pasos: [NivelAyuda] = [.completa, .inicio, .ninguna]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(pasos.enumerated()), id: \.offset) { numero, paso in
                let activo = paso == nivel
                let hecho = paso.rawValue < nivel.rawValue
                HStack(spacing: 6) {
                    Image(systemName: hecho ? "checkmark.circle.fill" : (activo ? "pencil.circle.fill" : "circle"))
                    if activo {
                        Text("Paso \(numero + 1) de 3")
                    }
                }
                .font(.system(.headline, design: .rounded).weight(.heavy))
                .foregroundStyle(activo ? Color.white : Color.morado)
                .padding(.horizontal, activo ? 16 : 10)
                .padding(.vertical, 10)
                .background(Capsule().fill(activo ? Color.morado : (hecho ? Color(hex: "DDF5E4") : Color.white)))
                .overlay(Capsule().strokeBorder(Color.morado.opacity(0.4), lineWidth: activo ? 0 : 2))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Letra \(letra), paso \(pasos.firstIndex(of: nivel).map { $0 + 1 } ?? 1) de 3")
    }
}
