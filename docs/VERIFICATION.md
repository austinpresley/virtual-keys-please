# Verification

Verified locally on November 9, 2026, with macOS 27 and Stream Deck 7.6.0 (23012).

- Seven Swift Testing checks pass. They cover the NIST AES-256-CBC vector,
  unrelated feature preservation, repeated use, invalid and future records,
  clock rollback, method changes, backup/restore and concurrent mutation.
- The in-app self-test passes a real CFPreferences write/read/restore in an
  isolated random domain, plus SF Symbol checks. It never changes Stream Deck.
- The read-only live inspector verifies Corsair's signature and the current
  activation method, derives the current Mac's key and reads the 2100 expiry.
- The real Pretty please button reaches You're already floating. Digests prove
  the activation value, every existing profile file and original executable are
  unchanged after repeated use. The original bundle's strict signature check passes.
- Every state has active-window light and dark snapshots under ignored shots/.
  Ready, working, success, already enabled, missing app, unsupported method,
  activation reset and restored states are legible and unclipped. All sixteen
  layout checks and the grid lint pass. The native buttons use the plum accent;
  the key characters change expression and celebrate success. The icon was
  reviewed in default, dark, tinted and clear looks, including small sizes.
- Release contains arm64 and x86_64 slices, each with macOS 13 minimum. The local
  Xcode 27 toolchain prints an Intel deprecation warning; the universal build
  and architecture checks succeed. There are no Swift compilation warnings.

Only Apple Silicon hardware has been tested live. Intel hardware, older macOS
versions and unreleased Stream Deck versions remain unverified. Compatibility
requires the recognized activation constant, key derivation and record format.
Notarization and final disk-image checks are recorded in the local release receipt.
