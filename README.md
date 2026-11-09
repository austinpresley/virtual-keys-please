# Virtual Keys Please

Open the app from its disk image. Click **Pretty please**, or drop Stream Deck
onto the window. Virtual Stream Deck gets a very long activation, and six little
key characters get a reason to celebrate.

No installer, terminal, account or extra tools are needed. The app keeps a
private backup and offers Restore Last Change. The signed Elgato bundle and
button profiles are preserved. See the bundled help for compatibility limits.

Build and validate locally with `./build.sh`, `swift test`,
`tools/selftest.sh` and `tools/snap.sh`. Build products are under `dist/`.
The universal release targets Intel and Apple Silicon on macOS 13 or later.
Only Stream Deck 7.6.0 on this Apple Silicon Mac has been verified live.

The implementation and recognition boundary are in [docs/METHOD.md](docs/METHOD.md).
There is no hosted CI or automatic update service.
