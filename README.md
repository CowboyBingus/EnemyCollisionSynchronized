> Release for Steam build 25480438 / EXE 1.8.46015.0. Offline checks passed; checked in live play.

![Enemy Collision Synchronized](assets/banner.png)

# Enemy Collision Synchronized

Keeps large enemy corpse collisions aligned with their bodies and curbs the renewed ragdoll movement that can occur in vanilla.

- **Fewer invisible obstructions.** Realigns displaced collision pieces on settled corpses so their blocking surfaces better match the visible body.
- **Calmer settled bodies.** Detects substantial renewed movement after a remote corpse has settled and stops its ongoing ragdoll synchronization.
- **Cleaner Impaler remains.** Disables the lingering collision on settled Impaler tentacle claws.
- **Coverage across factions.** Includes compatible large Terminid, Automaton and Illuminate enemies, including Bile Titans, Impalers, walkers and tripods.

Corpse bodies retain their normal physical collision. The changes run on your game client; install with Bingus Shared Loader, or use Vanilla Plus Megapack with the loader.

Release **v2.12.0**: fewer memory reads, no Lua garbage while idle, and a pause instead of a stop after errors elsewhere in the update chain. Measured in live play: 0.067 ms per frame in client missions and 0.004 on the ship. [Releases](https://github.com/CowboyBingus/EnemyCollisionSynchronized/releases) · [Install](INSTALL.txt) · [Build](CONTRIBUTING.md) · [Changelog](docs/RELEASE_NOTES.md) · [Performance profiling](docs/PERFORMANCE.md)

Download [Bingus Shared Loader v18 or newer](https://github.com/CowboyBingus/BingusSharedLoader/releases/latest) from its own repository. Enable the loader alongside this mod, or alongside Vanilla Plus Megapack.

Current version: **v2.12.0**, for game build **25480438**. See [changes](CHANGELOG.md) and [validation coverage](docs/MIGRATION_VALIDATION.md).

**AI disclosure:** Developed with assistance from GPT-6 Astra and Claude Opus 5.5.

## License

Zero-Clause BSD (0BSD): use, copy, modify and distribute for any purpose, with no conditions. See `LICENSE`.
