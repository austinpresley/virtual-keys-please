# Stories

## VKP-1 Portable activation
- Recognize the official Stream Deck bundle and matching method markers on Intel or Apple Silicon.
- Derive the record key from the target binary's verified salt and the current Mac's platform UUID. No machine identifier or derived key is embedded or logged.
- Preserve other feature entries; create and verify a backup before changing only FeatureUnlockData.
- Gracefully stop Stream Deck, apply and read back the change, and reopen it. Never force-quit.
- Repeated use is harmless. Unknown methods and damaged or foreign activation data produce clear outcomes.
- Restore only the last changed preference, and refuse to overwrite a later independent change.

UX: Drop Stream Deck onto the main window, drop it onto the Dock icon, or choose it with Command-O. A detected installed app also offers Pretty please. Success offers Open Stream Deck and explains Add Virtual Device. A quiet footer offers backups and restore. Failed recognition leaves all preferences unchanged.

## VKP-2 Little key party
- Six original key characters animate on launch, while working and after success.
- Light and dark appearance remain legible, with keyboard labels and a static Reduce Motion alternative.
- Unsupported, missing-app, busy, ready, already-enabled and success states fit in one window.

## VKP-3 Carry it anywhere
- Build a universal signed app with macOS 13 minimum and no runtime dependencies outside the OS.
- Run directly from a read-only disk image. Store backups only in the user's Application Support folder.
- Verify the activation core with isolated fixtures and verify the installed app locally without weakening its current activation.
- Deliver the disk image through Austin Deliveries. Document that only the installed 7.6.0 method has been verified live so far.
