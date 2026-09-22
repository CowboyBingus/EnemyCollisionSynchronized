# Enemy Collision Synchronized — technical notes

**Local candidate: v2.9; published release: v2.7.** v2.9 reduces snapshot allocations and repeated metadata decoding while preserving v2.7 scheduling, validation and repair/containment policy. See [measurements and client test instructions](PERFORMANCE.md). Coverage remains **21 compatible large-entity resources across Terminids, Automatons and Illuminate**. [Install and test](../INSTALL.txt). [Asset investigation and coverage](../../docs/CORPSE_MVP_V25_FACTIONS_2026-09-15.md).

| Faction | Included asset families and variants |
|---|---|
| Terminid | Impaler, Bile Titan and Gloom Titan, Charger variants, Spewer variants, dragon |
| Automaton | Assault walker, spawner walker, jammer spawner walker |
| Illuminate | Tripod, tripod tier 2, war machine |

These labels follow extracted assets. Selection requires the shared precise RagdollSync path with `force_corpse_on_stopped=1`; it is not a generic size or faction match. Tanks, aircraft and other entities using different corpse systems are outside this build. All 21 resources have reviewed settings, skeletons, state machines and auxiliary actor mappings. Automaton recordings now corroborate main-body counts and ordered actor names for all three Automaton resources; the new mod actions still need gameplay validation. The war machine additionally needs confirmation that its sixth authored main actor resolves at runtime: it has no matching skeleton node, and a missing actor causes the mod to skip that snapshot.

## Behavior

V2.5.1 incorporates the [two Automaton baseline missions](../../docs/CORPSE_MVP_V251_AUTOMATON_2026-09-15.md). Four assault-walker Corpses retained a dynamic torso and rocket pods with a static base. Their auxiliary colliders could remain displaced, but v2.5 skipped the whole mixed state. An exact three-name exception now permits auxiliary repair after Corpse conversion while every other enabled primary remains static. Main bodies keep their physical motion and collision; the RagdollSync stop/completion gates are unchanged. The captured 60 cm mixed-state failure and a 52 cm static spawner-walker offset are production reader/planner regressions.

The module scans at most 30 times per second. Each exact resource has an allowlist of skeleton size, ordered main-body names, intentionally disabled landing bodies and auxiliary actor/node mappings. The layouts have 6, 10, 14 or 15 main bodies and 99–210 skeleton nodes. Living enemies with unpopulated sync arrays, initial dynamic deaths, changed skeletons or actor identities, and incomplete disposal states are excluded.

For active remotely owned fixed RagdollSync bodies, the root must stay within 25 cm / 10 degrees for at least one second and three samples. Movement beyond 75 cm / 20 degrees then triggers containment. An individual limb moving more than 50 cm or 15 degrees relative to the root must persist across observations at least 100 ms apart. A coherent whole-body turn is not independent limb motion. Membership, lifecycle changes, invalid poses and observation gaps reset the guard.

V2.5 accepts a disabled main actor only when that exact name is authored to disable on landing. The assault walker can therefore retain six static main bodies with four landing bodies disabled. Both Illuminate tripod profiles intentionally disable all ten main bodies. A remote tripod remaining in that completed fixed state for one second and at least three samples uses the same native stop/completion route without reading disabled physics bodies. This additional path finishes a fully landed ragdoll without requiring a motion measurement from invalid body storage.

A trigger calls the verified native stop at `game.dll+0x7a33f0`, without rewinding the current pose. Every enabled main-body pose and entity, unit, manager, actor and static-state guard is rechecked. After a verified stop persists for one second, one normal completion request at `game.dll+0x111ed10` is routed to the owner. Requests are recorded separately from observed Corpse conversion. Gaining ownership of a corpse this mod stopped invokes the native owned-completion branch. A request is not a guaranteed conversion or despawn deadline.

Eligible auxiliary static colliders follow their authored skeleton nodes through engine position/rotation commands. Three settled Impaler tentacle-claw actors remain intentionally disabled. Main bodies and legs retain the game's collision state, including authored disabled actors. The module never re-enables them, retains no live pointers between polls and does not write raw physics, network, timer, executable or player state.

## Evidence and limits

The completed [v2.4 client test](../../docs/CORPSE_MVP_V24_LIVE_TEST_2026-09-15.md) logged seven verified stops; all 1,430 strict stopped-state main-body samples stayed fixed, and the user reported no jiggling. Five requested units were observed as normal Corpses. One stopped Impaler stayed in RagdollSync for almost four minutes before leaving tracking without an observed conversion. This supports the existing containment approach, not universal cleanup or the new factions' efficacy.

**Corpse-contact damage protection remains unverified.** The native impact callback does not check the stopped update gate, and separate overlap-damage systems may survive. Repairing displacement and containing motion can reduce related contacts, but does not establish protection from host-authoritative damage. No damage-system patch is added in v2.5.

This is an active gameplay candidate with no dry-run mode. Legitimate late disturbances can be suppressed, a held pose can look awkward, and pure skeleton movement without sufficient enabled main-body movement remains outside the motion detector. It does not create new death animations or guarantee smooth initial deaths. These limits also apply to the additional factions.

## Build and testing

Python 3.10+ and the project's Windows x64 LuaJIT build are required. Set `HD2_LUAJIT`, then run `python -B scripts/build.py` from this directory. `HD2_GAME_ROOT` overrides the default Steam installation. The builder checks executable fingerprints, runs the gameplay and performance regressions, compiles one Lua resource and creates the root `releases/Enemy-Collision-Synchronized-v2.9.zip`; it never installs or launches the game.

The checked-in [catalog](profiles/catalog.json) is the source of the embedded allowlist. After an evidence-backed catalog edit, run `python -B scripts/generate_profiles.py`; the build rejects stale generated code. Synthetic reader and policy tests exercise all 21 layouts, disabled landing bodies, static corpse filters, native stop/readback, completion and rejection paths. Existing recorded Titan/Impaler replays remain required gates. Synthetic native calls are stubs and do not prove in-game physics outcomes.

The manual tracker reads the same catalog and records all 21 resources. Its separate 24-test suite covers capture, stop/cancellation, multiple sessions and cross-faction review hints. Close and reopen the tracker after updating. Older recordings remain untouched. [Tracker instructions](../../docs/CORPSE_TRACKING.md).

Requires Bingus Shared Loader loader-v8 / API 1 or newer. Supported layout: Steam build 24826606 / EXE 1.8.45317.0. Provenance fields `runtime_verified=false` and `contact_damage_verified=false` describe pending validation; they do not disable actions. Both v2.4 and v2.5 ZIPs are preserved under `releases/`. Enable one version and restart into a fresh mission after switching.

## Release identity

v2.6 is named Enemy Collision Synchronized in Arsenal and in the versioned release ZIP. The existing manager GUID, `mods/cowboybingus/corpse_collision_repair` resource, `CorpseCollisionRepair` state and `CorpseCollisionRepair.log` filename remain unchanged so upgrades, the shared loader and the tracker continue to recognize it. The source directory retains its historical name for the same reason. The megapack pins the same compiled resource as the standalone release.
