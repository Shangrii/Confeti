import SwiftUI

@main
struct ConfetiApp: App {
    @State private var perfiles = PerfilesStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(perfiles)
        }
    }
}
