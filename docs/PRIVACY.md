# Publication privacy

The published source is an explicit allowlisted snapshot with a new Git history. Commit author and committer use the public CowboyBingus alias and GitHub noreply identity.

Private workspace history, raw gameplay recordings, player/session identifiers, memory dumps, native disassembly fixtures, screenshots supplied as artwork references, local logs, machine configuration, credentials, compiler binaries and extracted game files are excluded. Corpse tests construct synthetic geometry, identities and memory layouts. The bundle also retains previously anonymized sentry and vaulting decision/geometry fixtures with remapped identities; these contain no raw process dump or session metadata.

The audit scans every included source file and release ZIP entry for local identities, home/UNC paths, credentials, email/phone/account identifiers and network addresses. Encoded hexadecimal/decimal byte literals are scanned after decoding. PNG structure, CRCs and metadata chunks are checked. Git commit metadata and every staged blob are checked against the allowlist. ZIP timestamps are fixed and comments/extra fields are empty.

Public repository aliases, mod GUIDs, dependency commits, resource hashes, game-build fingerprints and native API offsets are intentional technical identifiers. The audit result applies to the exact inventory and release hashes, not the surrounding private workspace. Pattern checks cannot guarantee detection of every conceivable identifier.

Run `python -B scripts/privacy_audit.py --zip PATH` to recheck the publication inventory and an installable package. Add `--git` after committing to verify the complete reachable history and source tree.
