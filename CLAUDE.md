# Virtual Keys Please

Read docs/BRIEF.md for the product scope and docs/METHOD.md before changing activation handling.

The app runs from its disk image. Build products belong in dist/, never an automatically installed Applications copy. The activation core lives in VirtualKeysPleaseKit; Mac integration and SwiftUI live in VirtualKeysPlease.

Run tests and builds locally. Keep hosted CI disabled. Use ./build.sh, swift test --scratch-path "$HOME/Library/Developer/VirtualKeysPlease/build", tools/selftest.sh and tools/snap.sh. Inspect light and dark snapshots and run the shipped grid checks after UI changes. Snapshot mode is demonstration-only and must never access the real Stream Deck preference.

Preserve the official app bundle and its signature. Recognize the established method before editing only FeatureUnlockData. Derive keys on the current Mac; keep platform identifiers, derived keys and live activation values out of source, logs and reports. Every mutation needs a verified private backup and exact readback. Restore must preserve later independent changes.

Keep the single-window flow, native controls, original key characters and Reduce Motion behavior. macOS 13 compatibility is deliberate, so the view model uses ObservableObject rather than Observation. No database, background service, Accessibility permission or runtime dependency is needed.

Commit verified changes in small steps. Do not add a remote or publish the repository without Austin's instruction.
