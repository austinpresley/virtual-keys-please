import AppKit
import SwiftUI

@main
struct VirtualKeysPleaseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AppModel.shared
    var body: some Scene {
        Window("Virtual Keys Please", id: "main") {
            ContentView(model: model)
                .onAppear {
                    if !SelfCheck.runIfRequested() { model.start(); Snapshot.runIfRequested(model: model) }
                }
        }
        .defaultSize(width: 560, height: 600)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Choose Stream Deck…", action: model.choose).keyboardShortcut("o").disabled(model.busy)
                Divider()
                Button("Enable Virtual Keys") { model.enable() }
                    .keyboardShortcut("e").disabled(model.busy || model.target == nil)
                Button("Open Stream Deck", action: model.openStreamDeck).disabled(model.target == nil || model.busy)
                Divider()
                Button("Restore Last Change", action: model.restore)
                    .disabled(!model.hasBackup || model.busy || model.target == nil)
                Button("Show Backups", action: model.revealBackups).disabled(!model.hasBackup)
            }
            CommandGroup(replacing: .help) {
                Button("How Virtual Keys Please Works") {
                    if let url = Bundle.main.url(forResource: "How it works", withExtension: "html") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first { AppModel.shared.inspect(url, thenEnable: true) }
    }
}
