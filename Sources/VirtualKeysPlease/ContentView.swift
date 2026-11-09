import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var model: AppModel
    @Environment(\.colorScheme) private var scheme
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 44)
            Text("VIRTUAL KEYS PLEASE")
                .font(.system(size: 11, weight: .bold, design: .rounded)).tracking(2)
                .foregroundStyle(Palette.accent(scheme))
                .frame(maxWidth: .infinity).frame(height: 16)
                .gridProbe("wordmark", area: "page", edge: "content")
            KeyParty(visit: model.visit, isTargeted: isTargeted, event: model.celebration,
                     snapshot: model.isDemonstration && ProcessInfo.processInfo.environment["APP_SNAPSHOT"] != nil)
                .frame(maxWidth: .infinity).frame(height: 224)
                .gridProbe("keys", area: "page", edge: "content")
            Text(heading)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.ink(scheme)).multilineTextAlignment(.center)
                .frame(maxWidth: .infinity).frame(height: 48)
                .gridProbe("heading", area: "page", edge: "content")
            Text(message)
                .font(.system(size: 13)).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).lineSpacing(2)
                .frame(maxWidth: .infinity).frame(height: 56)
                .gridProbe("message", area: "page", edge: "content")
            actions.frame(maxWidth: .infinity).frame(height: 80)
                .gridProbe("actions", area: "page", edge: "content")
            targetLabel.frame(maxWidth: .infinity).frame(height: 32)
                .gridProbe("target", area: "page", edge: "content")
            Spacer(minLength: 0)
            footer.frame(maxWidth: .infinity).frame(height: 40)
                .gridProbe("footer", area: "page", edge: "content")
        }
        .padding(.horizontal, Space.margin).padding(.bottom, Space.margin)
        .frame(width: 560, height: 600)
        .background(Palette.paper(scheme))
        .overlay {
            if isTargeted {
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Palette.accent(scheme), style: StrokeStyle(lineWidth: 2, dash: [8, 8]))
                    .padding(Space.md).allowsHitTesting(false)
            }
            if GridOverlay.enabled { GridOverlay() }
        }
        .tint(Palette.accent(scheme)).gridArea("page", inset: Space.margin).noInitialFocus()
        .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted, perform: acceptDrop)
        .accessibilityElement(children: .contain)
    }

    private var heading: String {
        if model.isInspecting { return "Let me meet those keys." }
        switch model.visit {
        case .ready: return isTargeted ? "Yes, that one. Drop it!" : "Virtual keys, please."
        case .working: return "One tiny favor…"
        case .success: return "Your keys can float."
        case .already: return "You're already floating."
        case .missing: return "Where's your Stream Deck?"
        case .unsupported: return "These keys are a mystery."
        case .reset: return "One old setting needs a reset."
        case .restored: return "Right back where we started."
        }
    }

    private var message: String {
        if model.isInspecting { return "Checking the installed app. Your settings are staying put." }
        switch model.visit {
        case .ready: return "Drop the Stream Deck app here, or ask nicely below.\nNo installer. No extra tools."
        case .working: return model.detail.isEmpty ? "Saving a backup, then enabling virtual keys." : model.detail
        case .success, .already: return "In Stream Deck, choose Add Virtual Device\nfrom the device menu. Let the button arranging begin."
        case .missing: return "Drop the Elgato Stream Deck app here,\nor choose it below."
        case .unsupported: return model.detail.isEmpty ? "This version uses a method I don't recognize yet.\nNothing was changed." : model.detail
        case .reset: return "The old activation can't be read on this Mac.\nI can back it up and replace it. Your button layouts stay put."
        case .restored: return "Your previous activation setting is back.\nYour button layouts are right where you left them."
        }
    }

    @ViewBuilder private var actions: some View {
        VStack(spacing: Space.md) {
            if model.busy {
                ProgressView().controlSize(.small).accessibilityLabel("Enabling virtual keys")
            } else if [.success, .already].contains(model.visit) {
                Button("Open Stream Deck", action: model.openStreamDeck)
                    .buttonStyle(.borderedProminent).controlSize(.large).keyboardShortcut(.defaultAction)
                Button("Choose a different copy…", action: model.choose).buttonStyle(.link)
            } else if model.visit == .reset {
                Button("Back up & enable") { model.enable(allowReset: true) }
                    .buttonStyle(.borderedProminent).controlSize(.large).keyboardShortcut(.defaultAction)
                Button("Leave it alone") { model.visit = .ready }.buttonStyle(.link)
            } else {
                if model.target != nil && model.visit != .unsupported {
                    Button("Pretty please") { model.enable() }
                        .buttonStyle(.borderedProminent).controlSize(.large).keyboardShortcut(.defaultAction)
                        .help("Back up the activation setting, enable virtual keys, and reopen Stream Deck.")
                    Button("Choose Stream Deck…", action: model.choose).buttonStyle(.link)
                } else {
                    Button("Choose Stream Deck…", action: model.choose)
                        .buttonStyle(.bordered).controlSize(.large)
                }
            }
        }
    }

    @ViewBuilder private var targetLabel: some View {
        if let target = model.target {
            Label("Stream Deck \(target.version)", systemImage: "app.badge.checkmark")
                .font(.system(size: 11)).foregroundStyle(.secondary).help(target.url.path)
        } else {
            Label("Works offline, on this Mac", systemImage: "sparkle")
                .font(.system(size: 11)).foregroundStyle(.secondary)
        }
    }

    private var footer: some View {
        HStack(spacing: Space.md) {
            Text("A little courtesy. A lot of keys.").font(.system(size: 11)).foregroundStyle(.secondary)
            Spacer()
            if model.hasBackup {
                Menu {
                    Button("Restore Last Change", action: model.restore).disabled(model.busy || model.target == nil)
                    Button("Show Backups", action: model.revealBackups)
                } label: { Label("Backups", systemImage: "arrow.uturn.backward") }
                    .menuStyle(.borderlessButton).fixedSize().font(.system(size: 11)).disabled(model.busy)
            }
        }
    }

    private func acceptDrop(_ providers: [NSItemProvider]) -> Bool {
        guard !model.busy, let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL?
            if let data = item as? Data { url = URL(dataRepresentation: data, relativeTo: nil) }
            else { url = item as? URL }
            if let url { Task { @MainActor in model.inspect(url, thenEnable: true) } }
        }
        return true
    }
}
