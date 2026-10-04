# v2.12.0

- Errors from the game's update and shutdown, or from other mods, now reach the game unchanged with their original traceback, so they no longer look like errors in this mod.
- After a failed update of the game or of a mod loaded before it, the mod pauses: it sends no commands, forgets what it was tracking and reports `paused_after_update_error` once.
- It starts afresh after 60 updates in a row without such an error; 8 such errors in one burst stop it for the session.
- A collision check that raises an error on 8 polls in a row now stops the mod for the session instead of being retried forever.
- The shutdown status keeps the first failure or refusal (`stopped after: <reason>`); plain `stopped` now means nothing failed.
- An error in the mod's own shutdown work can no longer prevent the shutdown callbacks of the game and other mods.
- Performance profiling is off again unless `CowboyBingusDiagnostics = true` is set before the mod starts; since v2.10.2 it ran in every game and rewrote its log every 10 s.
- Without diagnostics, `CorpseCollisionRepair.log` is again written only at startup, when the mod stops and at shutdown.
- The opt-in profiler counts failed game updates without timing them.
- Polls outside a mission, on the ship and in a mission with nothing to inspect no longer allocate Lua memory (about 1.8-2.5 KB per poll before).
- Scanning living enemies allocates no Lua memory (up to 32 bytes per listed enemy before), and an enemy type the mod does not handle no longer makes a Lua string.
- Outside a mission and on the ship a poll makes 1 and 2 memory reads instead of 4 and 5.
- Scanning eight living enemies takes 19 memory reads instead of 26, and 1 clock read instead of 8.
- Each inspected ragdoll costs up to four memory reads fewer, and each inspected corpse two fewer; every value is still validated on its own.
- A settled remote ragdoll's motion check takes 128 memory reads instead of 155, and a corpse realignment 120 instead of 140.
- Inspections allocate less Lua memory (settled corpse 26.6 to 23.7 KB, settled ragdoll 47.4 to 37.0 KB, realignment 37.8 to 34.7 KB, synthetic scene).
- Pose values are decoded from bytes, so a corrupted (NaN) value is always rejected as invalid.
- Every Windows function the mod calls is declared under a private name, so another mod's declaration of the same function can no longer stop the memory reader from starting.
- The update chain runs through Bingus Shared Runtime's guard, and the game build check uses its per-session module hashes.
- The enemy allowlist moved to its own source file, `src/corpse_profiles.lua`, and the inspection is split into small named steps with the same results.
- The technical notes name the supported game build (25480438) and the native addresses the mod calls in it.
- The mod is now licensed under the Zero-Clause BSD license (0BSD).
- Requires Bingus Shared Loader v18 or newer.
- Measured in live play: 0.067 ms per frame in client missions (0.188 in the previous session, which had more ragdolls) and 0.004 on the ship.

# v2.11.0

- Guard validation compares fresh game bytes against a reusable buffer instead of copying each block into a Lua string: 10-35% less CPU per poll in the synthetic benchmark, most in repair-heavy scenes. The same reads, guards and results; profiling counts are unchanged.
- About half the Lua garbage per poll in realistic synthetic scenes, with a byte-identical command log (changes first built as v2.10.3, never released separately).
- A one-second cooldown before re-posing the same actor again for small corrections (under 10 cm and 5 degrees); larger gaps and rotations bypass it. This cuts repeated re-posing of settled Charger ragdolls.
- Measured in real play: about 0.29 ms to 0.14 ms of main-thread time per frame in missions.

# v2.10.2

- Update native guards and corpse state-machine asset hashes for Steam build 25480438.
- Preserve the 21-profile allowlist and opt-in profiling.
- Offline builds and package checks pass; live gameplay validation remains pending.

# v2.10.1

- Update compatibility for game build 25327279.
- Refresh enemy collision and ragdoll layouts, including Bile Spewers.
- Reduce repeated guard reads when no correction is needed.
- Keep routine performance logging disabled unless diagnostics are enabled.

# v2.9.2

- Make detailed performance profiling and periodic status logs opt-in.
- Remove routine profiler instrumentation and disk output from default gameplay.
- Preserve the published collision-repair behavior and validation guards.
- Offline regression checks cover this update; live frame-time verification remains pending.

# v2.9.1

- Moves logs to `%LOCALAPPDATA%\CowboyBingus\Helldivers2\Logs`.
- Requires Bingus Shared Loader v14 for the shared log folder.
