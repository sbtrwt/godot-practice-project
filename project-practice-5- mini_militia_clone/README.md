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
- [ ] Milestone 5 completion: Android export, device testing, persistence polish, and network soak testing.

The current player scene is intentionally a vertical slice. The next implementation should add touch controls, richer weapon Resources, projectile visuals, and Android export testing.

## Android testing

Install Godot's Android export templates and configure an Android export preset. Export a debug APK, install it on two phones, connect both phones to the same mobile hotspot, and use the host phone's local IP address. Keep UDP port `7777` available and test with the device firewall/network permissions enabled.
