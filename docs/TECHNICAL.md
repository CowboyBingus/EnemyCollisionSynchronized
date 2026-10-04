# Enemy Collision Synchronized — technical notes

**Release: v2.12.0, for Steam build 25480438; see the [changelog](../CHANGELOG.md).** v2.9 reduced snapshot allocations and repeated metadata decoding while preserving v2.7 scheduling, validation and repair/containment policy. See [measurements and client test instructions](PERFORMANCE.md). Coverage remains **21 compatible large-entity resources across Terminids, Automatons and Illuminate**. [Install and test](../INSTALL.txt). [Asset investigation and coverage](../../docs/CORPSE_MVP_V25_FACTIONS_2026-09-15.md).

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

A trigger calls the verified native stop at `game.dll+0x7abd00`, without rewinding the current pose. Every enabled main-body pose and entity, unit, manager, actor and static-state guard is rechecked. After a verified stop persists for one second, one normal completion request at `game.dll+0x13c0350` is routed to the owner. Requests are recorded separately from observed Corpse conversion. Gaining ownership of a corpse this mod stopped invokes the native owned-completion branch. A request is not a guaranteed conversion or despawn deadline.

Eligible auxiliary static colliders follow their authored skeleton nodes through engine position/rotation commands. Three settled Impaler tentacle-claw actors remain intentionally disabled. Main bodies and legs retain the game's collision state, including authored disabled actors. The module never re-enables them, retains no live pointers between polls and does not write raw physics, network, timer, executable or player state.

## Snapshot steps

`M.snapshot` (`src/corpse_data.lua`) reads the game in named steps, each of cognitive complexity 15 or less. `scan_poll` checks the mission mode and alternates which manager goes first. `scan_manager` reads a manager's header and bounds, then `scan_entities` walks its entries from a rotating cursor within the poll's budget. `visit` reads an entry's header and, for a listed resource, the cheap lifecycle check. `inspect_listed` runs `inspect` in `pcall`, so a failed read or check skips only that unit, and hands a complete unit to `consume` after the manager's globals are checked again. `inspect` builds the unit from `new_unit`, `ragdoll_runtime`, `skeleton`, `actor_handles` and one `inspect_actor` per actor (`actor_row`, `actor_body`, `count_main_body`, `actionable`, `poses`).

The steps share the poll's values (api, state, budget, mission mode, current manager) through upvalues that are set in the same poll before any step reads them. No address or copied byte survives into the next poll's decisions. The steps make the same native commands and results as the single function they replaced, and no closure per inspected unit.

## Per-poll cost

Each memory read and view is one `ReadProcessMemory` (about 1-2 us each in the game); the clock is one `QueryPerformanceCounter`, whose in-game cost is unmeasured. The mod makes no `VirtualQuery` call during play. Counts per poll, pinned by `tests/test_performance.lua` in its synthetic scene (Bile Titan layout):

| Poll | Reads + views | Clock |
| --- | --- | --- |
| Outside a mission | 1 | 1 |
| On the ship | 2 | 1 |
| Idle in a mission | 9 | 1 |
| Eight living enemies | 10 + 9 | 1 |
| One settled corpse inspected | 25 + 82 | 1 |
| One settled remote ragdoll inspected | 28 + 100 | 1 |
| One corpse realignment | 25 + 95 | 1 |

- The physics-getter preflight (3 reads) runs only in a mission, after the mission check.
- Each scanned entry's 24-byte header is one view; a string is made only for a listed resource. The sync counts of up to 16 listed entries come from one view at the array's 432-byte stride, copied into numbers; the copy is discarded after every inspection, so a count is never older than the last native command.
- The deadline clock is read every 8 scanned entries and after every inspection, not before every entry; a deadline seen in one manager also ends the other's scan. The 1 ms deadline stays soft.
- An inspection reads each enabled actor's 160-byte body through a view; only main bodies and bodies with a pending command become strings. Actor rows copied 16 at a time are decoded in place.
- The guards an inspection verified (and the manager globals verified right after it) are not compared again before the unit's first native command or its motion sample: no native call runs in between. Every native command after the first compares the unit's guards afresh, and each command still verifies its actor's own guards right before it. A unit's root pose guard is one of its main pose guards and is not compared twice.
- Pose floats are decoded from bytes by arithmetic: a NaN becomes Lua's own NaN, which the finiteness checks reject.

A settled corpse's cost is dominated by its enabled bodies (69 views in the scene): each is needed to compare its pose with its node. No layout is kept across polls.

Machine code: before the split, nothing outside the per-unit inspection compiled in the game's LuaJIT (`begin_snapshot`'s `pairs()` and the creation of the per-unit closure aborted every trace through it). Those steps therefore stay interpreted with `jit.off`, and the inspection steps compile as the closure's body did. `tests/test_performance.lua` pins the garbage per poll in every budget scenario, interpreted and compiled.

## Update chain and errors

The loader (`src/archive_loader.lua`) installs the game's `update` and `shutdown` chain through `runtime.guard` from Bingus Shared Runtime v1, vendored as `src/bingus_runtime.lua` with `src/bingus_memory.lua` (this mod writes no game memory directly, so it does not vendor `bingus_write.lua`). The build check takes the executable and game.dll hashes from the runtime's per-session cache.

- The previous update runs outside `pcall`, so its errors reach the game unchanged. A failed update below the mod (vanilla or a mod loaded earlier) is seen on the next frame.
- The mod then pauses. It does not poll, so it sends no native command. It forgets every unit, motion history, stop, scan position and cooldown (`M.reset`, the same reset as leaving a mission) and reports `paused_after_update_error` once. Once the updates below have returned on 60 frames in a row, it reports `resumed_after_60_clean_frames` and polls afresh. More errors below while it is paused restart those 60 frames.
- Eight errors below in one burst stop the mod for the session. A burst ends after 3600 frames whose update below returned, so rare errors never add up to a stop.
- Other errors in the mod's own frame reach the guard, which logs the first of each burst once; eight in one burst stop the mod.
- **Exception: the mod's own raised polls are counted in a row, not in bursts.** The loader runs each poll in its own `pcall`; a poll that raises is retried on the next poll. A successful poll resets the count, and 8 raised polls in a row stop the mod.
  - Why: these errors are mostly transient races with the game, such as units despawning in the middle of a read, and their rate in real play is unmeasured. Under the guard's burst rule, such races could stop the mod in the middle of a mission.
  - A pause keeps the count: polls on either side of it are still in a row.
- The shutdown status keeps the first failure or refusal (`stopped after: <reason>`). A pause alone is not a failure. An error in the mod's own shutdown work is caught and recorded, so the shutdown callbacks of the game and other mods still run.

`tests/test_loader.lua` covers each rule, including the exception.

## Evidence and limits

The completed [v2.4 client test](../../docs/CORPSE_MVP_V24_LIVE_TEST_2026-09-15.md) logged seven verified stops; all 1,430 strict stopped-state main-body samples stayed fixed, and the user reported no jiggling. Five requested units were observed as normal Corpses. One stopped Impaler stayed in RagdollSync for almost four minutes before leaving tracking without an observed conversion. This supports the existing containment approach, not universal cleanup or the new factions' efficacy.

**Corpse-contact damage protection remains unverified.** The native impact callback does not check the stopped update gate, and separate overlap-damage systems may survive. Repairing displacement and containing motion can reduce related contacts, but does not establish protection from host-authoritative damage. No damage-system patch is added in v2.5.

This is an active gameplay candidate with no dry-run mode. Legitimate late disturbances can be suppressed, a held pose can look awkward, and pure skeleton movement without sufficient enabled main-body movement remains outside the motion detector. It does not create new death animations or guarantee smooth initial deaths. These limits also apply to the additional factions.

## Build and testing

Python 3.10+ and the project's Windows x64 LuaJIT build are required. Set `HD2_LUAJIT`, then run `python -B scripts/build.py` from this directory. `HD2_GAME_ROOT` overrides the default Steam installation. The builder checks executable fingerprints, runs the gameplay and performance regressions, compiles one Lua resource and creates the root `releases/Enemy-Collision-Synchronized-v2.12.0.zip`; it never installs or launches the game.

The checked-in [catalog](../profiles/catalog.json) generates the allowlist, `src/corpse_profiles.lua`: data only, never edited by hand. `src/corpse_data.lua` holds the logic and takes the allowlist as its chunk argument; `scripts/module.py` embeds the profiles before it and passes them in, and `tests/test_module.lua` runs the built wrapper. After an evidence-backed catalog edit, run `python -B scripts/generate_profiles.py`; the build rejects a stale generated file and a module that would not embed every file in `src/`. Skeleton variants repeat their lists in the generated file, so each profile line carries an R14 `lint-ok` marker written by the generator. Synthetic reader and policy tests exercise all 21 layouts, disabled landing bodies, static corpse filters, native stop/readback, completion and rejection paths. Existing recorded Titan/Impaler replays remain required gates. Synthetic native calls are stubs and do not prove in-game physics outcomes.

The manual tracker reads the same catalog and records all 21 resources. Its separate 24-test suite covers capture, stop/cancellation, multiple sessions and cross-faction review hints. Close and reopen the tracker after updating. Older recordings remain untouched. [Tracker instructions](../../docs/CORPSE_TRACKING.md).

Requires Bingus Shared Loader v18 or newer (v19 is current); the module's own load check accepts loader-v8 / API 1 or newer. Supported layout: Steam build 25480438 / EXE 1.8.46015.0. Provenance fields `runtime_verified=false` and `contact_damage_verified=false` describe pending validation; they do not disable actions.

## Release identity

v2.6 is named Enemy Collision Synchronized in Arsenal and in the versioned release ZIP. The existing manager GUID, `mods/cowboybingus/corpse_collision_repair` resource, `CorpseCollisionRepair` state and `CorpseCollisionRepair.log` filename remain unchanged so upgrades, the shared loader and the tracker continue to recognize it. The source directory retains its historical name for the same reason. The megapack pins the same compiled resource as the standalone release.
