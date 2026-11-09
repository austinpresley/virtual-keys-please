# Activation method

The installed Stream Deck 7.6.0 app was inspected locally. Its feature store uses
an encrypted JSON object containing an epoch-seconds `now` and an `expires`
mapping. `expires["vsd.lock"]` controls Virtual Stream Deck availability.

The record is Base64 of a random 16-byte IV followed by AES-256-CBC ciphertext,
with zero padding. The key is SHA-256 of a 256-byte constant in the installed
binary followed by this Mac's UTF-8 IOPlatformUUID. This project includes only
a short recognition prefix and the constant's SHA-256 fingerprint. It extracts
the complete constant from the user's official application and derives the key
in memory. No captured key, platform identifier, live preference or vendor app
is included in source or distribution.

The utility verifies the application's bundle ID, Corsair signing team and code
signature, then requires the known feature-store strings and constant fingerprint.
It accepts different version numbers with that recognized method. This is a
compatibility check, not a promise about unreleased versions. Format changes or
new root JSON fields stop the operation. An unreadable old record requires an
explicit Back up & enable action before replacement.

The mutation preserves other feature-expiry entries, updates `now`, and sets
the virtual-key expiry to 4102444800, January 1, 2100. The app is stopped through
normal macOS termination, never force-quit. The previous preference is saved and
read back from a private backup before any preference write. CFPreferences saves
and verifies the single key. Existing button profiles and the target bundle are
not edited. No runtime injection is used by the finished utility.

Restore requires the current value to match the digest of the value written by
this utility, so a later independent activation is preserved. Backups contain
the old encrypted preference, metadata and digests, with directory mode 0700 and
file mode 0600. They never contain the derived key or machine identifier.

Tests cover a NIST AES vector, record preservation, idempotence, damaged and
future formats, constant changes, mutation races, private backups and restore.
The in-app self-test writes only a random temporary CFPreferences domain.
`--inspect /path/to/Stream Deck.app` is a read-only live compatibility check.
