Supports Helldivers 2 Steam build 25480438 / EXE 1.8.46015.0.

Offline source, package and read-only module checks passed. The v2.12.0 build
ran in two joined missions on 2026-10-04, where its per-frame cost was measured.
v2.13.0 waits for work, re-checks corpses that need no correction less often
and keeps a ragdoll's motion check in reused tables. Its per-frame cost was
measured in solo missions without enemy deaths; the corpse re-check schedule
was checked offline only.
Multiplayer authority, visual and corpse-contact damage validation remain
pending. The 21
external live checks did not write game memory or installed files.

Public source excludes raw memory captures and private session recordings.
Install with the game closed, then Purge / Deploy in one mod manager.
Use Bingus Shared Loader v18 or newer (v19 is current).
