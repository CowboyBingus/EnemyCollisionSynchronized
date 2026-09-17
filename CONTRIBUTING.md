# Build from source

Use Windows x64, Python 3.10+ and the LuaJIT commit pinned in `dependencies.json`. Build LuaJIT with `msvcbuild.bat nogc64` from an x64 Visual Studio Native Tools prompt, then set `HD2_LUAJIT` to that executable. Set `HD2_GAME_ROOT` if the supported Helldivers 2 installation is outside the standard Steam directory.

Run `python -B scripts/build.py`. The builder verifies the local game fingerprints, runs the profile, collision, snapshot, motion, settlement, completion, loader, bounded-work, profiler and package checks, and writes `releases/Enemy-Collision-Synchronized-v2.9.1.zip`. It does not launch or install into the game. See [performance profiling](docs/PERFORMANCE.md) for the synthetic benchmark and client capture instructions.

`profiles/catalog.json` generates the embedded resource allowlist. After a reviewed catalog change, run `python -B scripts/generate_profiles.py`; the build rejects stale generated code.

Private recorded-session replays are intentionally excluded from public source. The published tests use synthetic identities and geometry; offline checks do not establish live gameplay outcomes. Build outputs and local game/compiler inputs must remain untracked.

See [publication privacy](docs/PRIVACY.md) for the source inventory and release audit. No repository-wide license has been selected.
