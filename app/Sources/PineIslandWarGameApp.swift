import SwiftUI

/// Pine Island War Game — one app for iPhone, iPad and Mac.
/// The game runs from the bundled index.html, fully offline; this shell gives it a
/// native window, haptics, and keeps the browser out of sight.
@main
struct PineIslandWarGameApp: App {
    var body: some Scene {
        WindowGroup {
            GameScreen()
        }
        #if os(macOS)
        .defaultSize(width: 1280, height: 860)
        .commands {
            CommandGroup(replacing: .newItem) {}       // one battlefield at a time
            CommandGroup(replacing: .help) {
                Button("Rules and Controls") { GameBridge.shared.send("ui.showHelp()") }
                    .keyboardShortcut("/", modifiers: .command)
            }
        }
        #endif
    }
}

/// Parchment-dark background matching the game, so no white flash at launch or rotation.
extension Color {
    static let warGameBackground = Color(red: 0.114, green: 0.094, blue: 0.071)
}

struct GameScreen: View {
    var body: some View {
        ZStack {
            Color.warGameBackground.ignoresSafeArea()
            GameWebView()
                .ignoresSafeArea()          // the game pads itself with env(safe-area-inset-*)
        }
        #if os(iOS)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)  // tuck the home indicator away during play
        #endif
        #if os(macOS)
        .frame(minWidth: 860, minHeight: 600)
        #endif
    }
}
