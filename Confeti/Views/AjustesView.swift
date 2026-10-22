import SwiftUI

/// Ajustes para el adulto: voz, sonidos, jugadores y la evaluación del trazo.
/// Sirve para afinar probando con niños reales, sin recompilar.
struct AjustesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PerfilesStore.self) private var perfiles

    @AppStorage(Claves.guiaVoz) private var guiaVoz = true
    @AppStorage(Claves.sonidos) private var sonidos = true
    @AppStorage(Claves.musica) private var musica = true
    @AppStorage(Claves.tolerancia) private var tolerancia = Valores.tolerancia
    @AppStorage(Claves.cobertura1) private var cobertura1 = Valores.cobertura1
    @AppStorage(Claves.cobertura2) private var cobertura2 = Valores.cobertura2
    @AppStorage(Claves.precision2) private var precision2 = Valores.precision2
    @AppStorage(Claves.cobertura3) private var cobertura3 = Valores.cobertura3
    @AppStorage(Claves.precision3) private var precision3 = Valores.precision3
    @AppStorage(Claves.umbrales) private var umbrales = Valores.umbrales

    @State private var textoUmbrales = ""
    @State private var porBorrar: Perfil?

    private var errorUmbrales: String? {
        ValidadorUmbrales.error(en: textoUmbrales)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Voz y sonido") {
                    Toggle("Instrucciones habladas", isOn: $guiaVoz)
                        .onChange(of: guiaVoz) { _, activa in
                            if !activa { Voz.shared.detener() }
                        }
                    Toggle("Sonidos de retroalimentación", isOn: $sonidos)
                    Toggle("Música de fondo", isOn: $musica)
                        .onChange(of: musica) { _, _ in
                            Musica.shared.actualizar()
                        }
                }

                Section {
                    if perfiles.perfiles.isEmpty {
                        Text("Todavía no hay jugadores.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(perfiles.perfiles) { perfil in
                        jugador(perfil)
                    }
                } header: {
                    Text("Jugadores")
                } footer: {
                    Text("Las estrellas de prueba sirven para revisar los desbloqueos. Borrar un jugador elimina todo su avance.")
                }

                Section {
                    deslizador("Tolerancia R", valor: $tolerancia, rango: 0.04...0.30)
                } header: {
                    Text("Tolerancia del trazo")
                } footer: {
                    Text("Porcentaje de la altura de la letra. Qué tan lejos de la línea puede pasar el dedo y seguir contando como acierto.")
                }

                Section {
                    deslizador("Cobertura para decir «¡Bien hecho!»", valor: $cobertura1, rango: 0.30...1)
                } header: {
                    Text("1 estrella")
                } footer: {
                    Text("Si terminó el trazo siempre gana 1 estrella. Debajo de este corte la app dice «Casi, va otra vez».")
                }

                Section("2 estrellas") {
                    deslizador("Cobertura mínima", valor: $cobertura2, rango: 0.30...1)
                    deslizador("Precisión mínima", valor: $precision2, rango: 0.30...1)
                }

                Section("3 estrellas (además, orden correcto)") {
                    deslizador("Cobertura mínima", valor: $cobertura3, rango: 0.30...1)
                    deslizador("Precisión mínima", valor: $precision3, rango: 0.30...1)
                }

                Section {
                    TextField("15, 30, 50, 75, 105, 140, 180, 225", text: $textoUmbrales)
                        .keyboardType(.numbersAndPunctuation)
                        .onChange(of: textoUmbrales) { _, nuevo in
                            if ValidadorUmbrales.error(en: nuevo) == nil {
                                umbrales = nuevo
                            }
                        }
                    if let errorUmbrales {
                        Label(errorUmbrales, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(Color.morado)
                            .accessibilityLabel("Aviso: \(errorUmbrales)")
                    } else {
                        Label("Guardado", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(Color.verdeTexto)
                    }
                } header: {
                    Text("Estrellas para desbloquear piñatas")
                } footer: {
                    Text("8 números de menor a mayor, separados por comas. Las primeras 3 piñatas siempre están disponibles. Mientras haya un aviso, la app sigue usando los últimos valores válidos.")
                }

                Section {
                    Button("Restaurar valores iniciales", action: restaurar)
                }
            }
            .navigationTitle("Ajustes para adultos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
            .onAppear { textoUmbrales = umbrales }
            .confirmationDialog(
                "¿Borrar a \(porBorrar?.nombre ?? "")?",
                isPresented: Binding(get: { porBorrar != nil }, set: { if !$0 { porBorrar = nil } }),
                titleVisibility: .visible
            ) {
                Button("Borrar jugador y su avance", role: .destructive) {
                    if let perfil = porBorrar {
                        perfiles.borrar(perfil.id)
                    }
                    porBorrar = nil
                }
                Button("Cancelar", role: .cancel) { porBorrar = nil }
            }
        }
    }

    private func jugador(_ perfil: Perfil) -> some View {
        HStack(spacing: 14) {
            Image(Coleccion.pinata(id: perfil.pinataActiva).imagen)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(perfil.nombre).font(.headline)
                Text("\(perfil.estrellas) estrellas · \(perfil.dominados(en: .letras)) letras y \(perfil.dominados(en: .numeros)) números con 3 estrellas")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("+10 ⭐") {
                perfiles.actualizar(perfil.id) { $0.estrellas += 10 }
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Sumar 10 estrellas de prueba a \(perfil.nombre)")
            Button(role: .destructive) {
                porBorrar = perfil
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Borrar a \(perfil.nombre)")
        }
    }

    private func deslizador(_ titulo: String, valor: Binding<Double>, rango: ClosedRange<Double>) -> some View {
        let porcentaje = Int((valor.wrappedValue * 100).rounded())
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(titulo)
                Spacer()
                Text("\(porcentaje) %")
                    .monospacedDigit()
                    .bold()
            }
            Slider(value: valor, in: rango, step: 0.01)
                .accessibilityLabel(titulo)
                .accessibilityValue("\(porcentaje) por ciento")
        }
    }

    private func restaurar() {
        guiaVoz = true
        sonidos = true
        musica = true
        tolerancia = Valores.tolerancia
        cobertura1 = Valores.cobertura1
        cobertura2 = Valores.cobertura2
        precision2 = Valores.precision2
        cobertura3 = Valores.cobertura3
        precision3 = Valores.precision3
        umbrales = Valores.umbrales
        textoUmbrales = Valores.umbrales
    }
}

#Preview {
    AjustesView()
        .environment(PerfilesStore.vistaPrevia())
}
