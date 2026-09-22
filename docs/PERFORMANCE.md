# Performance investigation and profiling — v2.9

Players report substantial improvement from v2.7 but some residual performance impact. v2.8 expands the evidence collected during gameplay; it does not change repair policy or claim an additional FPS improvement.

## What changed

The v2.6 reader limited accepted corpses but could scan every living enemy in the manager on each poll. Its read counters excluded repeated validation reads. Matrix decoding also allocated a new buffer and copied a trailing substring for each scalar, while every memory read allocated another buffer.

v2.7 rejects living enemies before deep inspection, reuses read scratch space, decodes bounded slices of copied data, and batches nearby validation reads while comparing every original guard. Each update starts at most 128 entity-header checks or four deep inspections, with a soft 1 ms deadline. An already-started inspection and its validated commands finish atomically, so an individual poll can exceed 1 ms. Both managers resume from rotating indices; entity pointers and command inputs are freshly read each time.

The repair and motion-containment actions remain enabled. Entity identity, membership, lifecycle, main-pose and between-command checks remain in place. These changes do not disable corpse collision or remove a class of enemies from coverage.

Work deferred by the budget runs on later updates. Under extreme corpse counts, repairs can be delayed and a corpse's observation gap can exceed one second. The motion detector then discards its old baseline and must observe settlement again. History expiry alone can also mean despawn or a lifecycle change: v2.8 separately measures actual revisits of the same active, remote, settled ragdoll. Continuous detection of every corpse under an arbitrary load is not guaranteed.

v2.8 adds eight worst-poll records, recent-window and mission statistics, lifecycle/ownership costs, sampled snapshot sections, optional thread-cycle/heap probes and timings around the update chain that this mod wraps. The 30 Hz schedule, work limits, native actions and all repair guards remain unchanged. The observational replay verifies identical reads, repair poses, verified stops and completion requests with profiling enabled and disabled.

## v2.9 inspection optimizations

Decoded world, body-array and actor-pool metadata is reused only within a poll, matching the existing copied-byte cache lifetime. Pointer reads use scratch storage. Copied node matrices are reused within each unit, and exactly identical body/node poses skip unnecessary conversion and comparison work. Auxiliary guard tables are constructed only for actions that need them; all copied predicates and fresh checks before each command remain. Corpse primary identity/motion and pose guards remain, while unused primary pose vectors are not decoded for Corpse-phase units.

No cross-poll address cache or reduced inspection frequency was introduced. Existing 30 Hz scheduling, work limits, thresholds, target catalog and native repair/containment actions remain. `world_metadata_decodes` and `pool_metadata_decodes` report actual metadata decoding operations; the repair log's `getter_checks` continues to count world lookups, including reuse of a result verified in that poll.

The disappearing-parts report remains a separate unresolved investigation; this version does not claim to fix it. See the workspace optimization report for equal-work benchmark results. Those results measure mod work in synthetic scenes, not game FPS.

## Capture a client test

1. Close the game. Replace the old standalone package with `Enemy-Collision-Synchronized-v2.9.zip`, or update to `Vanilla-Plus-Megapack-v8.zip`. Keep Bingus Shared Loader v12 or newer for the megapack. Purge / Deploy, then launch normally.
2. If both standalone and megapack are enabled, give the updated package winning priority over older copies. Check the first line of `%LOCALAPPDATA%/CorpseCollisionRepair.log` says `v2.9` and the performance log says `schema=2`.
3. Join another player's mission and play through a busy fight, including large enemy deaths. Profiling starts automatically; the separate corpse tracker is not required. Avoid running the detailed tracker during a performance comparison because it adds its own read overhead.
4. After the busy section, copy `%LOCALAPPDATA%/EnemyCollisionSynchronized-Performance.log`. Copy `%LOCALAPPDATA%/CorpseCollisionRepair.log` too, and note the observed FPS, whether you were host/client, and whether corpse behavior was normal.

The performance log is bounded, refreshed at most once every ten seconds and flushed on a normal shutdown. It retains launch totals and the eight worst polls, plus statistics since the last successful write. Copy it soon after a slowdown to preserve the recent window; save a copy before relaunching, because a new game process replaces the file. No hotkeys or extra configuration are required. The performance log contains no player/account information, entity pointers or positions. It is not a complete gameplay recording.

For a useful FPS comparison, repeat a similar client mission with the mod disabled and enabled. Enemy counts, host and map should be as similar as practical. A single mission cannot establish a guaranteed FPS improvement.

## Reading the report

- `mod_ms_mean`, `mod_ms_p95_upper`, `mod_ms_max`: callback cost per poll. The p95 is a histogram bucket upper bound, not an exact percentile.
- `mod_ms_per_second`: total callback elapsed time per wall second, including possible descheduling. This is not CPU utilization. The update count/rate is not a GPU FPS measurement.
- `mission_poll` / `outside_mission_poll`: separate in-mission cost from ship/loading time. `window_polls` / `window`: recent cost and counts exceeding 2/8/16/33 ms, normally covering about ten seconds. The recent window resets only after a successful write.
- `dominant_phase` and `phase=...`: exclusive time in discovery, snapshot construction, validation, planning, motion checks, native dispatch, maintenance and status logging. All reads are counted; individual read timings sample one poll in thirty.
- `snapshot_section=...`: sampled metadata, skeleton, actor-header and physics-body costs and read counts. These cover one poll in thirty and exclude nested validation. They are a breakdown of snapshot work, not additional time to add to it.
- `enemy=...` / `workload=...`: inspection cost by enemy and by lifecycle/ownership, including its validation and repair work. Lifecycles distinguish dynamic, settled or stopped ragdolls and aligned, repairable or other corpses. These overlap phase totals and must not be added to them. Rejected/unclassified visits stay visible.
- `slow_poll_rank=...`: eight worst polls, with relative time, mission scope, manager populations, phase costs, work/repair counter deltas and the most expensive unit category. Manager counts can include living entities. This captures cost correlation, not proof an enemy caused a stall.
- `wrapped_update`: elapsed time inside the previous update callback, including vanilla and earlier wrappers. It excludes this mod and any later wrappers, and does not attribute individual engine subsystems. `update_interval` measures entry spacing; neither measures GPU FPS or network delay.
- `thread_cycles` and `heap_delta_kb`: supporting context for slow polls. Cycles are raw current-thread counters and must not be converted to milliseconds; heap changes cover the shared Lua VM and do not prove a GC pause. Missing probes report `unavailable`. See [Microsoft's cycle-counter documentation](https://learn.microsoft.com/en-us/windows/win32/api/realtimeapiset/nf-realtimeapiset-querythreadcycletime).
- `slow_mod_poll`: at least one poll exceeded 2 ms. `work_deferred`: the scheduler yielded. `late_ragdoll_revisit`: the same identified active, remote, settled ragdoll was observed again after more than one second. The telemetry cache is limited to 256 slots; evictions mean some gaps cannot be measured. Ordinary expiry remains a separate `history_expirations` counter and `history_expiry_age_max_seconds`, never evidence by itself of starvation. Flags are cumulative.
- `profiler_output_ms_max` and `profiler_finish_ms_*`: separate formatting/IO and end-of-poll bookkeeping costs, excluded from `mod_ms_*`. Other in-poll instrumentation remains included. `slow_diagnostic_output` flags output over 2 ms. File errors do not disable repairs; optional profiler setup/callback failures disable telemetry and increment `profiler_failures` in the repair log.
- Repair, stop, completion and retry counters show what the mod actually attempted. Native timings measure dispatch only; they cannot measure deferred engine physics work or host-authoritative damage.

## Earlier optimization measurements (v2.6 to v2.7)

Measured in a synthetic native-layout scene inside the test process, using the production Windows memory-read adapter. Native mutators are stubs. Each case has ten warmup polls and 100 measured polls. The v2.7 column includes the automatic profiler; it excludes the periodic log-file write, which is reported separately during gameplay.

| Scene | v2.6 mean ms/poll | v2.7 mean ms/poll | v2.7 p95 ms/poll | Reads/poll before → after |
| --- | ---: | ---: | ---: | ---: |
| Empty managers | 0.025 | 0.032 | 0.135 | 13 → 9 |
| 256 living enemies | 2.660 | 0.385 | 0.578 | 1,294 → 266 |
| 1,500 living enemies | 19.910 | 0.377 | 0.547 | 7,514 → 266 |
| 32 ragdolls + 32 corpses | 229.945 | 1.533 | 2.285 | 45,042 → 206 |
| 500 living + 48 ragdolls + 48 corpses | 240.802 | 1.513 | 2.137 | 46,717 → 233 |

This is a comparison of work per poll, not equal throughput: v2.7 spreads inspections across polls. The older history-expiry flag did not distinguish actual late revisits from despawns. These timings demonstrate the scaling problem and bounded work, but do not predict real-game FPS or prove the reported FPS loss is fully resolved.

Run `luajit tests/benchmark.lua src tests/perf_scene.lua profile OUTPUT_DIRECTORY` from the mod directory to reproduce the candidate benchmark. The output directory must exist. The regression suite separately checks fair progress through both managers, living-crowd rejection, budget boundaries, arming and verified motion containment amid a living crowd, expired histories, and identity changes between native commands. Recorded-session replays continue to exercise the existing repair and containment decisions; they do not benchmark live physics.
