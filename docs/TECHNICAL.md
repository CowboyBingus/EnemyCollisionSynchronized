# Enemy Collision Synchronized implementation

The resource allowlist covers 21 compatible large Terminid, Automaton and Illuminate assets and 680 auxiliary actor/node mappings. Exact resource, skeleton, main-body, disabled-body and actor identities are checked before an action. Unsupported layouts fail closed.

Settled static auxiliary colliders are moved to their authored skeleton nodes through engine position and rotation commands. Three settled Impaler tentacle-claw colliders are disabled. Main corpse collision remains governed by the game.

Remote fixed ragdolls must remain quiet for one second and at least three observations before the renewed-motion detector arms. Root movement above 0.75 m or 20 degrees triggers a native stop. Independent limb movement above 0.5 m or 15 degrees must persist across at least 0.1 seconds of observations. Ordinary initial dynamic deaths, invalid poses, changed identities, ownership changes and observation gaps are excluded or reset the detector.

After a verified stop persists for one second, one normal completion request is routed to the owner. A request is distinct from observed conversion or despawn. All-disabled landed tripods use a guarded fixed-state completion path. Assault-walker Corpses with the three allowlisted dynamic upper-body actors can receive auxiliary-only repair while the remaining enabled main actors are static.

The current code does not directly patch damage callbacks. Reducing displaced collision and renewed motion is not a guarantee against every corpse-contact damage mechanism. Offline synthetic tests validate selection, native-command dispatch models and guards; live native physics outcomes require gameplay observations.

The public v2.6 name retains the existing manager GUID, `mods/cowboybingus/corpse_collision_repair` resource, `CorpseCollisionRepair` state and `CorpseCollisionRepair.log` filename for compatible upgrades. The gameplay source compiles to the same resource as the prepared local v2.6 release. Private session material is not distributed.

Requires Bingus Shared Loader v8 or newer / API 1; download the loader separately from its own repository. Supported game fingerprints are pinned in `scripts/archive.py` for Steam build 24826606 / EXE 1.8.45317.0.
