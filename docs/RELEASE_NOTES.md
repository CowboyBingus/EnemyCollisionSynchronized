# v2.9.2

- Make detailed performance profiling and periodic status logs opt-in.
- Remove routine profiler instrumentation and disk output from default gameplay.
- Preserve the published collision-repair behavior and validation guards.
- Offline regression checks cover this update; live frame-time verification remains pending.

# v2.7

- Reduced processing overhead when many enemies and corpses are present.
- Spread collision checks across updates to reduce performance spikes during crowded fights.
- Removed redundant memory reads and reduced temporary allocations.
- Added automatic performance logging to help identify remaining hotspots.
- Retained existing corpse collision repairs and ragdoll stabilization safeguards.

# v2.6

Renamed Corpse Collision Repair to Enemy Collision Synchronized. Includes the Impaler banner and all-caps Arsenal square, consistent versioned package names and the established collision/motion policy across 21 compatible large enemy resources. Stable module identity and manager GUID preserve upgrades.
