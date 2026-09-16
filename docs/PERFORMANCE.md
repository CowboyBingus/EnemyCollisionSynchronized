# Performance investigation and profiling — v2.7

Players reported severe FPS loss with Enemy Collision Synchronized enabled, especially when joining another player. Disabling the mod restored performance. Local reproduction of that exact live-game FPS loss is still pending.

## What changed

The v2.6 reader limited accepted corpses but could scan every living enemy in the manager on each poll. Its read counters excluded repeated validation reads. Matrix decoding also allocated a new buffer and copied a trailing substring for each scalar, while every memory read allocated another buffer.

v2.7 rejects living enemies before deep inspection, reuses read scratch space, decodes bounded slices of copied data, and batches nearby validation reads while comparing every original guard. Each update starts at most 128 entity-header checks or four deep inspections, with a soft 1 ms deadline. An already-started inspection and its validated commands finish atomically, so an individual poll can exceed 1 ms. Both managers resume from rotating indices; entity pointers and command inputs are freshly read each time.

The repair and motion-containment actions remain enabled. Entity identity, membership, lifecycle, main-pose and between-command checks remain in place. These changes do not disable corpse collision or remove a class of enemies from coverage.

Work deferred by the budget runs on later updates. Under extreme corpse counts, repairs can be delayed and a corpse's observation gap can exceed one second. The motion detector then discards its old baseline and must observe settlement again. This deliberately preserves the existing safety rule; the profiler flags these gaps. Continuous detection of every corpse under an arbitrary load is not guaranteed.

## Capture a client test

1. Close the game. Replace the old standalone package with `Enemy-Collision-Synchronized-v2.7.zip`, or update to `Vanilla-Plus-Megapack-v4.zip`. Keep Bingus Shared Loader v9 or newer. Purge / Deploy, then launch normally.
2. If both standalone and megapack are enabled, give the updated package winning priority over older copies. Check the first line of `%LOCALAPPDATA%/CorpseCollisionRepair.log` says `v2.7`.
3. Join another player's mission and play through a busy fight, including large enemy deaths. Profiling starts automatically; the separate corpse tracker is not required. Avoid running the detailed tracker during a performance comparison because it adds its own read overhead.
4. After the busy section, copy `%LOCALAPPDATA%/EnemyCollisionSynchronized-Performance.log`. Copy `%LOCALAPPDATA%/CorpseCollisionRepair.log` too, and note the observed FPS, whether you were host/client, and whether corpse behavior was normal.

The performance log is a bounded aggregate, refreshed at most once every ten seconds and flushed on a normal shutdown. It reports totals since this game launch, not a full gameplay recording. Save a copy before relaunching; a new game process replaces the file. No hotkeys or extra configuration are required. It contains no player/account information, entity pointers or positions.

For a useful FPS comparison, repeat a similar client mission with the mod disabled and enabled. Enemy counts, host and map should be as similar as practical. A single mission cannot establish a guaranteed FPS improvement.

## Reading the report

- `mod_ms_mean`, `mod_ms_p95_upper`, `mod_ms_max`: callback cost per poll. The p95 is a histogram bucket upper bound, not an exact percentile.
- `mod_ms_per_second`: total callback CPU time per elapsed second. The game update count/rate is not a GPU FPS measurement.
- `dominant_phase` and `phase=...`: exclusive time in discovery, snapshot construction, validation, planning, motion checks, native dispatch, maintenance and status logging. All reads are counted; individual read timings sample one poll in thirty.
- `enemy=...`: inspection cost and read counts by supported enemy type, including its validation and repair work. These overlap phase totals and must not be added to them.
- `slow_mod_poll`: at least one poll exceeded 2 ms. `work_deferred`: the scheduler yielded. `motion_history_sampling_gap`: a motion baseline expired after a gap longer than one second. These are cumulative indicators, not proof the latest fight caused them.
- `profiler_output_ms_max`: separate cost of formatting/writing the aggregate. `slow_diagnostic_output` flags output over 2 ms. File errors do not disable gameplay repairs.
- Repair, stop, completion and retry counters show what the mod actually attempted. Native timings measure dispatch only; they cannot measure deferred engine physics work or host-authoritative damage.

## Offline measurements

Measured in a synthetic native-layout scene inside the test process, using the production Windows memory-read adapter. Native mutators are stubs. Each case has ten warmup polls and 100 measured polls. The v2.7 column includes the automatic profiler; it excludes the periodic log-file write, which is reported separately during gameplay.

| Scene | v2.6 mean ms/poll | v2.7 mean ms/poll | v2.7 p95 ms/poll | Reads/poll before → after |
| --- | ---: | ---: | ---: | ---: |
| Empty managers | 0.025 | 0.032 | 0.135 | 13 → 9 |
| 256 living enemies | 2.660 | 0.385 | 0.578 | 1,294 → 266 |
| 1,500 living enemies | 19.910 | 0.377 | 0.547 | 7,514 → 266 |
| 32 ragdolls + 32 corpses | 229.945 | 1.533 | 2.285 | 45,042 → 206 |
| 500 living + 48 ragdolls + 48 corpses | 240.802 | 1.513 | 2.137 | 46,717 → 233 |

This is a comparison of work per poll, not equal throughput: v2.7 spreads inspections across polls. The largest synthetic cases triggered the sampling-gap flag. These timings demonstrate the scaling problem and bounded work, but do not predict real-game FPS or prove the reported FPS loss is fully resolved.

Run `luajit tests/benchmark.lua src tests/perf_scene.lua profile OUTPUT_DIRECTORY` from the mod directory to reproduce the candidate benchmark. The output directory must exist. The regression suite separately checks fair progress through both managers, living-crowd rejection, budget boundaries, arming and verified motion containment amid a living crowd, expired histories, and identity changes between native commands. Recorded-session replays continue to exercise the existing repair and containment decisions; they do not benchmark live physics.
