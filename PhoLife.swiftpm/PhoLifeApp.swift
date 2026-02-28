import SwiftUI

@main
struct PhoLifeApp: App {
    init() {
        FontManager.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .persistentSystemOverlays(.hidden)
        }
    }
}
