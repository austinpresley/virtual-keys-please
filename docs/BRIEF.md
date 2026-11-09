# Virtual Keys Please

A small, playful Mac utility that enables Virtual Stream Deck through its local activation record.

## Replaces
Repeating the manual activation-record repair after an update or reset.

## Main jobs
1. Find the installed Stream Deck, or accept its app by drag and drop.
2. Recognize the established activation method, back up the existing value, and extend Virtual Stream Deck access through 2100.
3. Reopen Stream Deck, explain how to add a virtual device, and offer a narrow restore.

## Data
- Target app: URL, version, signing identity, compatible activation-method fingerprint.
- Backup: previous activation value, written-value fingerprint, timestamp and target version.
- Activation: current timestamp and feature-expiry mapping, preserving other entries.

## Shape
One window. Universal Intel and Apple Silicon app, macOS 13 or later. Runs from a disk image without an installer. Works offline, with no accounts or helper dependencies. Decided by the agent from Austin's request.

## System hooks
Application-bundle drops, app discovery, graceful Stream Deck restart and one preference-key update. No Accessibility permission or background service.

## Reference
The verified local Stream Deck 7.6.0 activation-record repair from November 9, 2026.

## Look
Native Mac controls with a warm plum accent and six original animated key characters. Gentle idle motion, an eager drop response and a brief success celebration. Respect Reduce Motion. Decided by the agent.

## Not in version one
- Modifying or re-signing Stream Deck, or installing anything into its bundle.
- Guessing at a changed activation algorithm.
- Accounts, telemetry, network services or automatic update monitoring.

## Design plan
Single task window; no sidebar or Settings. The drop area is the main entry point, with Choose Stream Deck in File / Command-O as an alternative. Return triggers the visible primary button. Escape cancels selection. Restore Last Change is in File. An unrecognized app produces an inline explanation. The intended feeling is a polite little favor, done quickly.
