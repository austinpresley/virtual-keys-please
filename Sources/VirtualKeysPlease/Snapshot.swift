import AppKit
import SwiftUI

enum Snapshot {
    static func runIfRequested(model: AppModel) {
        guard let folder = ProcessInfo.processInfo.environment["APP_SNAPSHOT"], model.isDemonstration else { return }
        Task {
            do {
                try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true)
                try await Task.sleep(for: .milliseconds(500))
                let activation = NSWorkspace.OpenConfiguration()
                activation.activates = true
                activation.createsNewApplicationInstance = false
                _ = try await NSWorkspace.shared.openApplication(at: Bundle.main.bundleURL, configuration: activation)
                for mode in ["light", "dark"] {
                    NSApp.appearance = NSAppearance(named: mode == "light" ? .aqua : .darkAqua)
                    for visit in Visit.allCases {
                        model.visit = visit
                        model.target = visit == .missing || visit == .unsupported ? nil : InstalledTarget(
                            url: URL(fileURLWithPath: "/Applications/Elgato Stream Deck.app"),
                            version: "7.6.0", binaryDigest: "demo", salt: Data())
                        model.detail = visit == .working ? "Saving a backup, then enabling virtual keys." : ""
                        model.hasBackup = [.success, .restored].contains(visit)
                        try await Task.sleep(for: .milliseconds(240))
                        try await capture(to: URL(fileURLWithPath: folder).appendingPathComponent("\(visit.rawValue)-\(mode).png"))
                    }
                }
                print("PASS snapshots: every state in light and dark")
            } catch {
                FileHandle.standardError.write(Data("Snapshot failed: \(error.localizedDescription)\n".utf8))
                exit(1)
            }
            NSApp.terminate(nil)
        }
    }

    private static func capture(to url: URL) async throws {
        guard let window = NSApp.windows.first(where: { $0.canBecomeMain && $0.isVisible }) else {
            throw CocoaError(.fileNoSuchFile)
        }
        if NSApp.isHidden { NSApp.unhideWithoutActivation() }
        NSApp.setActivationPolicy(.regular)
        if #available(macOS 14, *) { NSApp.activate() }
        else { NSApp.activate(ignoringOtherApps: true) }
        window.makeKeyAndOrderFront(nil)
        try await Task.sleep(for: .milliseconds(300))
        guard window.isKeyWindow, NSApp.isActive else { throw CocoaError(.featureUnsupported) }
        let size = window.contentView?.bounds.size ?? .zero
        GridProbes.shared.write(to: url.deletingPathExtension().path + "-layout.json", window: size)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-x", "-o", "-l", String(window.windowNumber), url.path]
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0, FileManager.default.fileExists(atPath: url.path) else {
            throw CocoaError(.fileWriteUnknown)
        }
        print("SNAPSHOT \(url.path)")
    }
}
