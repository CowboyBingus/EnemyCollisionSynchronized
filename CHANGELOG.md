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
