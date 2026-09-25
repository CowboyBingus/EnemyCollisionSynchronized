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
