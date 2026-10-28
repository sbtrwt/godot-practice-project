# LAN Mini Militia Clone

Godot 4 foundation for a component-based, server-authoritative 2D LAN shooter.

## Current scaffold

- Godot 4 project with typed GDScript.
- Composition root scene with host/join controls.
- ENet LAN service using UDP port `7777`.
- Event bus, save service, player definition Resource, player entity, and health component.
- Hybrid MVVM direction: application/UI ViewModels can be added without forcing MVVM onto every gameplay entity.
- Milestone 2 foundation: peer-aware player spawning and multiplayer authority assignment.

## Run

1. Open this directory in Godot 4.x.
2. Run the project.
3. On one device, press **Host**.
4. On another device on the same mobile hotspot, enter the host's local IP and press **Join**.

## Milestones

- [x] Milestone 1: offline vertical slice and host/join shell.
- [x] Milestone 2 foundation: peer-aware player entities and authority boundaries.
- [x] Milestone 3: authoritative input replication and remote-player interpolation.
- [x] Milestone 4 foundation: authoritative hitscan combat, damage, scoring, respawn, and match state machine.
- [x] Milestone 5 foundation: touch action buttons and Resource-driven weapon tuning.
- [x] Production hardening foundation: atomic saves and debug network overlay.
- [x] Playable match presentation: bounded arena and match HUD.
- [x] Reference movement slice: gravity, horizontal movement, and jetpack thrust.
- [x] Original prototype character sprite sheet integrated into the player scene.
- [x] Character presentation switches between idle and jetpack sprite poses.
- [x] Reference-style twin-stick controls: left movement/jetpack joystick, right aim joystick, and tap/hold fire.
- [x] Aim direction and muzzle-flash feedback for authoritative shots.
- [x] Authoritative grenade touch zone with cooldown and area damage prototype.
- [x] Per-player health bars driven by the HealthComponent.
- [x] Headless-safe scene fallback when external art import is unavailable.
- [x] Explicit LAN lobby flow with host-controlled match start.
- [x] Live LAN lobby player list.
- [x] Match results state and host-controlled return to lobby.
- [x] Headless core-rule smoke tests for health and weapon cooldown behavior.
- [x] Versioned save schema with v1-to-v2 migration defaults.
- [x] Visible network recovery action after connection failure or transport reset.
- [x] Deterministic debug simulation hooks for packet loss and snapshot latency.
- [x] Asset-independent island arena presentation with terrain, rocks, hills, and palms.
- [x] Collision surfaces aligned with the five visible island platforms.
- [x] Centralized bounded error-reporting ring buffer for recovery diagnostics.
- [x] Host lobby displays a discoverable LAN IPv4 address and UDP port.
- [x] Arena layout is configured through an `ArenaDefinition` Resource.
- [x] Composition-root validation for player, weapon, and arena Resources.
- [x] Deterministic 1,000-packet network soak assertion for loss and latency configuration.
- [x] Peer nameplates keep remote players identifiable during LAN matches.
- [x] Lobby persists and restores the last successful host IP through `SaveService`.
- [x] Match HUD consumes a dedicated `MatchViewModel` presentation adapter.
- [x] Touch controls show explicit move, jetpack, aim, fire, and grenade affordances.
- [x] Host-authoritative three-second warmup phase precedes live match scoring.
- [x] Established clients recover visibly when the host disconnects.
- [x] Fresh host/join/reset actions clear stale network diagnostics.
- [x] Host address selection prefers private hotspot IPv4 ranges over virtual/link-local adapters.
- [ ] Milestone 5 completion: successful Android export/device testing, profiling/soak execution, resource validation, and final gameplay-system replacement.

The current player scene remains a prototype vertical slice. Remaining work is release validation and replacing prototype shortcuts with dedicated gameplay systems.

## Automated validation

Run the dependency-free gameplay smoke tests from the project directory:

```text
Godot_v4.7-stable_win64_console.exe --headless --path . --script res://tests/test_core_rules.gd
```

The command exits with status `0` only when health and weapon cooldown invariants pass.

In debug builds, `NetworkService.configure_simulation(true, latency_ms, packet_loss_percent)` can be used by soak harnesses to exercise delayed snapshots and dropped client input. Defaults are zero latency and zero packet loss.

## Android testing

An `Android Debug` export preset is checked in. Install Godot's Android export templates and SDK/JDK, then export a debug APK with:

The preset explicitly enables Android Internet permission because ENet LAN sessions use UDP networking.

```text
Godot_v4.7-stable_win64_console.exe --headless --path . --export-debug "Android Debug" build/lan-mini-militia-debug.apk
```

The command is a packaging preflight; successful export does not replace physical device testing. Install the APK on two phones, connect both phones to the same mobile hotspot, use the host phone's local IP address, and keep UDP port `7777` available.
