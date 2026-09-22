![Enemy Collision Synchronized](assets/banner.png)

# Enemy Collision Synchronized

Keeps large enemy corpse collisions aligned with their bodies and curbs the renewed ragdoll movement that can occur in vanilla.

- **Fewer invisible obstructions.** Realigns displaced collision pieces on settled corpses so their blocking surfaces better match the visible body.
- **Calmer settled bodies.** Detects substantial renewed movement after a remote corpse has settled and stops its ongoing ragdoll synchronization.
- **Cleaner Impaler remains.** Disables the lingering collision on settled Impaler tentacle claws.
- **Coverage across factions.** Includes compatible large Terminid, Automaton and Illuminate enemies, including Bile Titans, Impalers, walkers and tripods.

Corpse bodies retain their normal physical collision. The changes run on your game client; install with Bingus Shared Loader, or use Vanilla Plus Megapack with the loader.

Current release: **v2.9.2**. [Install](INSTALL.txt) · [Build](CONTRIBUTING.md) · [Changelog](CHANGELOG.md)

Download [Bingus Shared Loader v14 or newer](https://github.com/CowboyBingus/BingusSharedLoader/releases/latest) from its own repository. Enable the loader alongside this mod, or alongside Vanilla Plus Megapack.

Release **v2.9.2** includes input/performance fixes. Offline checks cover this revision; in-game frame-time validation is pending. Routine diagnostics are off by default; developers can set `CowboyBingusDiagnostics = true` before initialization to enable them.
