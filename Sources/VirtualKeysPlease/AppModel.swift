import AppKit
import Combine
import UniformTypeIdentifiers
import VirtualKeysPleaseKit

enum Visit: String, CaseIterable {
    case ready, working, success, already, missing, unsupported, reset, restored
}

/// ObservableObject keeps the tiny app compatible with macOS 13.
final class AppModel: ObservableObject {
    static let shared = AppModel()
    @Published var visit: Visit = .ready
    @Published var target: InstalledTarget?
    @Published var detail = ""
    @Published var isInspecting = false
    @Published var hasBackup = false
    @Published var celebration = UUID()
    private var pendingDrop: URL?
    let inspector = TargetInspector()
    let worker = ActivationWorker()
    let isDemonstration = ProcessInfo.processInfo.environment["APP_SNAPSHOT"] != nil
        || ProcessInfo.processInfo.arguments.contains("--demo")

    var busy: Bool { visit == .working || isInspecting }

    func start() {
        guard !isDemonstration else {
            target = InstalledTarget(url: URL(fileURLWithPath: "/Applications/Elgato Stream Deck.app"),
                                      version: "7.6.0", binaryDigest: "demo", salt: Data())
            return
        }
        if let url = StreamDeckLifecycle.installedURL() { inspect(url) }
        else { visit = .missing }
        Task { hasBackup = await worker.hasBackup() }
    }

    func choose() {
        guard !busy else { return }
        let panel = NSOpenPanel()
        panel.title = "Choose Stream Deck"
        panel.message = "Choose the Elgato Stream Deck app."
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        if panel.runModal() == .OK, let url = panel.url { inspect(url) }
    }

    func inspect(_ url: URL, thenEnable: Bool = false) {
        if isInspecting && thenEnable { pendingDrop = url; return }
        guard !busy else { return }
        if isDemonstration {
            if thenEnable { enable() }
            return
        }
        isInspecting = true
        detail = ""
        Task {
            do {
                target = try await inspector.inspect(url)
                visit = .ready
                isInspecting = false
                if let pending = pendingDrop {
                    pendingDrop = nil
                    inspect(pending, thenEnable: true)
                } else if thenEnable { enable() }
            } catch {
                target = nil
                detail = error.localizedDescription
                visit = .unsupported
                isInspecting = false
                if let pending = pendingDrop {
                    pendingDrop = nil
                    inspect(pending, thenEnable: true)
                }
            }
        }
    }

    func enable(allowReset: Bool = false) {
        guard !busy, let target else { return }
        visit = .working
        detail = "Stream Deck will briefly restart."
        Task {
            if isDemonstration {
                try? await Task.sleep(for: .seconds(2))
                visit = .success
                celebration = UUID()
                return
            }
            var wasRunning = false
            do {
                // Recheck the bundle immediately before touching the preference.
                let checked = try await inspector.inspect(target.url)
                wasRunning = try await StreamDeckLifecycle.stop(checked)
                let already = try await worker.apply(to: checked, allowReset: allowReset)
                hasBackup = await worker.hasBackup()
                try await StreamDeckLifecycle.open(checked, activate: false)
                visit = already ? .already : .success
                celebration = UUID()
            } catch {
                if wasRunning { try? await StreamDeckLifecycle.open(target, activate: false) }
                detail = error.localizedDescription
                visit = (error as? KeysError) == .unreadableActivation ? .reset : .unsupported
            }
        }
    }

    func openStreamDeck() {
        guard let target else { return }
        if isDemonstration { celebration = UUID(); return }
        Task {
            do { try await StreamDeckLifecycle.open(target) }
            catch { detail = error.localizedDescription; visit = .unsupported }
        }
    }

    func restore() {
        guard !busy, hasBackup, let target else { return }
        visit = .working
        detail = "Putting your previous setting back."
        Task {
            var wasRunning = false
            do {
                wasRunning = try await StreamDeckLifecycle.stop(target)
                try await worker.restore()
                try await StreamDeckLifecycle.open(target, activate: false)
                visit = .restored
            } catch {
                if wasRunning { try? await StreamDeckLifecycle.open(target, activate: false) }
                detail = error.localizedDescription
                visit = .unsupported
            }
        }
    }

    func revealBackups() {
        let directory = ThisMac.backupDirectory
        if FileManager.default.fileExists(atPath: directory.path) {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: directory.path)
        }
    }
}
