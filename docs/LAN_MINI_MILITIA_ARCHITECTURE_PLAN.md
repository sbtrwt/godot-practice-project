# LAN Multiplayer 2D Shooter — Architecture and Implementation Plan

## 1. Purpose and scope

This document defines a production-oriented architecture for a Godot 4, mobile-first, 2D multiplayer shooter inspired by the *genre* of small arena jetpack games. It is intended for LAN play over a mobile Wi-Fi hotspot and should remain extensible to Internet multiplayer later.

Initial target:

- 2D side-view arena
- 2–6 players per match
- Host-authoritative LAN multiplayer over ENet/UDP
- Android touch controls, with keyboard/controller support for development
- One arena, one player archetype, a small weapon set, respawn, score, and match timer

Non-goals for the first milestone: accounts, cloud matchmaking, ranked play, cosmetics, voice chat, and a dedicated Internet backend.

## 2. Architectural principles

1. **Server authority:** clients send intent; the host validates and owns important game state.
2. **Composition over inheritance:** gameplay entities are assembled from components rather than deep class hierarchies.
3. **Pure domain rules where practical:** movement, damage, inventory, and scoring rules should be testable without rendering or UI.
4. **Explicit boundaries:** UI, presentation, gameplay, networking, persistence, and platform code communicate through contracts.
5. **Data-driven configuration:** balance and content live in typed `Resource` files, not hard-coded scene scripts.
6. **Deterministic message flow:** commands enter systems, systems produce state changes and events, views react to state.
7. **Observability by default:** logging, metrics, debug overlays, replay-friendly events, and error codes are designed in early.

## 3. Recommended project layout

```text
res://
├── app/
│   ├── bootstrap/
│   ├── composition_root/
│   └── app_state/
├── core/
│   ├── contracts/              # Interfaces and small shared types
│   ├── events/                 # Event bus and event definitions
│   ├── commands/               # Command definitions and dispatcher
│   ├── errors/                 # Error codes, result types, error service
│   ├── logging/
│   └── time/
├── domain/
│   ├── entities/
│   ├── components/
│   ├── systems/
│   ├── rules/
│   └── value_objects/
├── gameplay/
│   ├── match/
│   ├── spawning/
│   ├── combat/
│   ├── movement/
│   └── scoring/
├── networking/
│   ├── lobby/
│   ├── transport/
│   ├── replication/
│   ├── prediction/
│   └── protocol/
├── presentation/
│   ├── entities/
│   ├── effects/
│   ├── camera/
│   └── animation/
├── ui/
│   ├── views/
│   ├── view_models/
│   ├── navigation/
│   └── controls/
├── data/
│   ├── weapons/
│   ├── players/
│   ├── maps/
│   ├── modes/
│   └── balance/
├── persistence/
│   ├── save_service.gd
│   ├── save_schema.gd
│   └── migrations/
├── debug/
│   ├── debug_overlay.gd
│   ├── cheats.gd
│   └── network_simulator.gd
├── scenes/
├── assets/
└── tests/
    ├── unit/
    ├── integration/
    └── multiplayer/
```

## 4. Composition root and dependency injection

Create one startup scene that constructs application services and registers them as autoloads or explicit dependencies. Avoid having gameplay nodes search globally for arbitrary nodes.

Recommended services:

- `EventBus`
- `CommandBus`
- `NetworkService`
- `MatchService`
- `SaveService`
- `ErrorService`
- `Logger`
- `ContentRegistry`
- `Clock`
- `SceneLoader`

The composition root chooses the runtime mode:

```text
Offline test | LAN host | LAN client | Dedicated server
```

Systems should depend on interfaces or narrow service contracts. This makes offline tests possible without starting a real network peer.

## 5. Entity and component model

Use Godot scenes as composition templates and nodes as components. Keep an entity thin: it owns identity and component discovery; components own focused behavior.

Example player scene:

```text
PlayerEntity (CharacterBody2D)
├── IdentityComponent
├── InputComponent
├── MovementComponent
├── AimComponent
├── HealthComponent
├── WeaponComponent
├── InventoryComponent
├── NetworkIdentityComponent
├── ReplicationComponent
├── AnimationComponent
└── PlayerPresentation
```

Component rules:

- One responsibility per component.
- Components communicate through commands and events, not direct chains of unrelated references.
- Components expose typed methods and signals.
- Components should be reusable for bots, players, projectiles, and pickups where possible.
- Rendering components must not decide authoritative damage, score, inventory, or match outcomes.

Use a small `EntityContext` or injected service bundle when a component needs shared services. Do not turn every component into an autoload.

MVVM is not required for every entity. Use components and systems for simulation; add a ViewModel only when an entity has complex presentation state shared by multiple visual views.

## 6. Gameplay systems

Systems process groups of components and coordinate domain rules. Suggested systems:

- `InputSystem`: converts device input into player commands.
- `MovementSystem`: validates and applies movement intent.
- `AimSystem`: normalizes aim direction and facing.
- `WeaponSystem`: validates cooldown, ammunition, fire mode, and creates shot commands.
- `ProjectileSystem`: moves projectiles and resolves collision requests.
- `DamageSystem`: applies validated damage and emits death events.
- `HealthSystem`: handles damage, invulnerability, death, and respawn eligibility.
- `InventorySystem`: owns weapon and ammunition state.
- `SpawnSystem`: selects spawn points and creates entities through factories.
- `MatchSystem`: controls warmup, playing, score limit, timer, and results.
- `ScoreSystem`: awards points using match rules.
- `ReplicationSystem`: publishes authoritative state snapshots.
- `CleanupSystem`: removes expired projectiles, effects, and disconnected entities.

Systems should run in a known order. Gameplay-critical systems run on the authority; clients run presentation, local input, prediction, and interpolation systems.

## 7. Commands, events, and buses

### Commands

Commands represent intent and are handled by one owner. Examples:

- `JoinLobbyCommand`
- `StartMatchCommand`
- `MovePlayerCommand`
- `AimPlayerCommand`
- `FireWeaponCommand`
- `ReloadWeaponCommand`
- `RequestRespawnCommand`
- `LeaveMatchCommand`

Commands should contain validated value objects such as player ID, tick, direction, and sequence number. Client-originated commands must be rate-limited and validated on the host.

### Events

Events represent facts that already happened. Examples:

- `PeerConnectedEvent`
- `PlayerSpawnedEvent`
- `WeaponFiredEvent`
- `DamageAppliedEvent`
- `PlayerDiedEvent`
- `ScoreChangedEvent`
- `MatchStartedEvent`
- `MatchEndedEvent`
- `NetworkErrorEvent`

### Event bus

Use one typed event bus for cross-module communication. Events should be immutable data objects. Subscribers must unsubscribe when their owner exits the tree. The bus is for notification, not for hidden control flow; use commands for requests.

## 8. Factory and registry patterns

Use factories to create runtime objects from data and identity, rather than scattering `preload()` and initialization logic throughout systems.

Recommended factories:

- `PlayerFactory`
- `ProjectileFactory`
- `PickupFactory`
- `WeaponFactory`
- `EffectFactory`
- `ViewModelFactory`

Use a `ContentRegistry` to map stable IDs to `Resource` definitions and packed scenes. Validate the registry at startup and fail with a useful error if a referenced asset is missing.

## 9. Resource-driven configuration

Create typed custom Resources for all content and balance values:

```text
WeaponDefinition
├── weapon_id
├── display_name
├── fire_mode
├── damage
├── fire_rate
├── projectile_definition
├── magazine_size
├── reload_time
└── audio/effect references
```

Other Resources:

- `PlayerDefinition`
- `ProjectileDefinition`
- `MapDefinition`
- `GameModeDefinition`
- `MovementDefinition`
- `TouchControlDefinition`
- `MatchRulesDefinition`
- `NetworkTuningDefinition`

Keep runtime state separate from definitions. A `WeaponDefinition` is immutable content; a weapon component owns current ammunition and cooldown.

## 10. Hybrid MVVM architecture

Use MVVM at application and presentation boundaries, not as the universal architecture for every gameplay entity. MVVM is valuable when state is complex, shared by multiple views, network-facing, or worth testing independently.

Use MVVM for:

- Main menu, lobby, matchmaking, and connection status.
- HUD, scoreboard, pause, results, settings, and loadout screens.
- Player/enemy nameplates, health bars, status displays, and interaction prompts.
- Spectator, replay, tutorial, progression, and debug screens.
- Complex entity presentation where several views consume the same state.

Do not use MVVM for:

- Movement, physics, collision, shooting, damage, inventory rules, or server authority.
- Simple bullets, particles, pickups, projectiles, and one-off effects.
- Every component or every scene by default.

Recommended boundary:

```text
Gameplay entity = identity + components + authoritative state
Gameplay systems = simulation and rules
ViewModel = optional presentation adapter
View = sprites, animations, effects, and controls
```

For a complex player or enemy:

```text
PlayerEntity
├── Components and authoritative state
├── PlayerPresentationViewModel
└── PlayerPresentationView
```

The ViewModel may expose `health_ratio`, `is_reloading`, `aim_angle`, `display_name`, and `animation_state`. It must not decide damage, movement validity, score, or match outcomes.

```text
View (Control or presentation scene)
    ↓ user interaction
ViewModel (presentation state + commands)
    ↓
Application service / CommandBus
    ↓
Domain and networking
    ↑ events/state projections
ViewModel
    ↑ observable properties
View
```

Rules:

- Views contain layout and input wiring only.
- ViewModels expose typed observable properties and UI commands.
- ViewModels do not own gameplay rules.
- HUD ViewModels subscribe to match/player projections, not directly to every gameplay node.
- Entity ViewModels are optional and reserved for complex presentation state.
- Simple visual nodes may use direct typed signals from a component or presentation adapter.
- Navigation is handled by a `ScreenRouter` or `NavigationService`.
- Keep UI state separate from replicated gameplay state.

Useful ViewModels:

- `MainMenuViewModel`
- `LobbyViewModel`
- `MatchHudViewModel`
- `ScoreboardViewModel`
- `SettingsViewModel`
- `ResultsViewModel`

## 11. LAN multiplayer design

Use Godot's high-level multiplayer API with `ENetMultiplayerPeer`.

### Session flow

```text
Host selects Create Game
→ Host creates ENet server on a fixed UDP port
→ Host displays local IP and QR/manual join code
→ Clients connect to host IP and port
→ Host authenticates a short session token/name
→ Host sends lobby snapshot
→ Host starts match when ready
```

The host is the authority. Clients send input, not final positions or damage results.

### Replication model

Replicate:

- Player transform and velocity snapshots
- Aim direction and facing
- Current animation state
- Health and shield state
- Weapon and ammunition state
- Projectiles or hit results
- Match timer and scores

Use reliable RPCs for lifecycle and match-critical events. Use unreliable sequenced updates for frequent transforms and aim data. Include tick/sequence numbers so stale packets can be discarded.

### Client responsiveness

- Local client prediction for its own movement.
- Host reconciliation when authoritative snapshots arrive.
- Interpolation for remote players.
- Short input buffer for temporary packet loss.
- Server-side cooldown and movement validation.

Do not over-engineer rollback for the first LAN milestone. Add it only if the game requires fast competitive shooting and testing shows it is necessary.

### Match lifecycle

Model the match as an explicit state machine:

```text
Offline → Hosting/Joining → Lobby → Loading → Warmup → Playing
→ RoundEnd → Results → Lobby
```

Only the authority may transition the authoritative match state.

## 12. Save, settings, and persistence

Implement a `SaveService` with versioned data and atomic writes.

Persist locally:

- Display name
- Audio and graphics settings
- Control layout
- Preferred weapon/loadout
- Statistics and unlocks, if included

Do not persist authoritative match state in the first LAN version. Use a schema version and migration functions so future releases can evolve safely. Save through a temporary file and replace the old file only after the write succeeds.

## 13. Error handling and recovery

Define stable error codes instead of relying only on raw strings:

- `NETWORK_PORT_IN_USE`
- `NETWORK_HOST_UNREACHABLE`
- `NETWORK_CONNECTION_TIMEOUT`
- `NETWORK_PROTOCOL_MISMATCH`
- `CONTENT_MISSING`
- `SAVE_CORRUPTED`
- `MATCH_FULL`
- `INVALID_COMMAND`

Use a `Result`-style return for expected failures and exceptions only for truly unexpected programmer errors. Route user-facing errors through an `ErrorService` that emits events consumed by UI ViewModels.

Every network failure should provide a recovery action such as retry, return to lobby, or recreate host.

## 14. Debugging and observability

Build debug tools before content becomes large:

- Categorized logger with timestamps and peer IDs.
- Toggleable network overlay: ping, packet loss, tick, interpolation delay.
- Entity inspector and component state viewer.
- Match state and authority indicator.
- Spawn and collision visualization.
- Deterministic random seed display.
- Input and command counters.
- Network simulator for latency, jitter, packet loss, and duplication.
- Debug-only commands gated behind a local development flag.

Never ship unrestricted cheat/debug commands in a production build. Keep logs free of secrets and avoid logging sensitive device data.

## 15. Testing strategy

### Unit tests

Test pure rules without scenes:

- Weapon cooldown and ammunition.
- Damage and armor calculations.
- Movement limits.
- Spawn selection.
- Score and match rules.
- Save migrations.
- Command validation.

### Integration tests

- Host creates and closes a session.
- Client joins and leaves.
- Lobby transitions to match.
- Player spawn and despawn.
- Damage, death, and respawn replication.
- Host migration is explicitly unsupported or tested if later implemented.

### Soak and network tests

- Two to six clients for 30–60 minutes.
- Packet loss and high latency.
- Host disconnect.
- Device sleep/wake.
- Hotspot disabled and re-enabled.
- Mismatched game versions.
- Malformed or excessive client commands.

## 16. Security and multiplayer trust model

LAN does not mean trusted. Validate every client-originated command on the host:

- Player owns the entity being controlled.
- Input rate is within limits.
- Movement is physically possible.
- Fire rate and ammunition are valid.
- Damage claims are never accepted directly from clients.
- Lobby names and payloads are length-limited.
- Protocol/game version is checked before joining.

For Internet release, add authentication, encrypted transport or a secure session layer, dedicated servers, abuse controls, and a real backend. Do not expose the LAN host protocol directly to the public Internet without redesigning its security model.

## 17. Delivery milestones

### Current implementation status

The current Godot project has completed the foundations of Milestones 1–5:

- Offline player vertical slice with health and respawn.
- ENet host/join flow for LAN sessions.
- Peer-aware player spawning and authority assignment.
- Client input submission, host simulation, snapshots, prediction, and interpolation.
- Host-authoritative hitscan combat, cooldown validation, damage, scoring, and match timer.
- Touch action buttons shared with the desktop InputMap.
- Resource-driven player and weapon tuning.
- Atomic local save replacement and a debug network/FPS overlay.
- Bounded arena collision and a presentation-only match HUD.
- Side-view movement tuning with gravity, horizontal input, and jetpack thrust.
- Original transparent character sprite sheet integrated through the presentation layer.
- Character presentation switches sprite regions for idle and jetpack poses without changing gameplay authority.
- Touch input is centralized in `InputService`; the left joystick drives movement/jetpack, the right joystick drives aim, and fire is a separate touch gesture.
- Shot presentation is broadcast from the authority so aim lines and muzzle flashes remain presentation-only feedback.
- Grenade requests are validated by the host and resolve area damage on the authority; projectile visuals remain a follow-up presentation task.
- Player health bars are presentation nodes driven by component signals, keeping health rules out of the view.
- The live scene has a deterministic vector fallback when a runtime cannot import external raster/vector art; source art remains versioned for editor/device builds.
- The LAN flow now keeps peers in the lobby until the host explicitly starts the match.
- The lobby exposes a live peer list through the application/presentation boundary.
- Match results can return to the lobby through a host-authorized service command without restarting the session.
- Core health and weapon cooldown invariants have a dependency-free headless smoke-test entry point.
- Save payloads are versioned at schema 2, with a tested v1-to-v2 migration for profile and control defaults.
- A checked-in Android Debug export preset makes APK packaging reproducible; physical device and hotspot validation remains an explicit release gate.
- Connection failures now reset the transport and expose a visible lobby recovery action instead of leaving the user in a stale connecting state.
- Debug builds include deterministic packet-loss and snapshot-latency hooks for repeatable network soak tests; production defaults remain disabled.
- The prototype map now has a deterministic code-native terrain presentation layer, so gameplay remains visually usable when external art import is unavailable.
- The visible island platforms have matching static collision surfaces for gravity, landing, and jetpack traversal.
- Network failures are recorded through a bounded ErrorService ring buffer, keeping recovery diagnostics separate from gameplay state.
- Host setup now displays the selected LAN IPv4 address and UDP port for clients on the same hotspot.
- Arena decoration and platform layout are now data-driven through an `ArenaDefinition` Resource, enabling map variants without renderer edits.
- Player, weapon, and arena Resources are validated at startup and in the headless test suite before gameplay uses them.
- Arena validation rejects malformed platform types, non-positive dimensions, and out-of-bounds geometry.
- Player death presentation now has an authority-driven respawn window; hidden players cannot collide or immediately re-enter combat.
- Authoritative hitscan resolution broadcasts a short-lived impact marker without coupling hit feedback to damage rules.
- Authoritative kills publish a bounded kill-feed event; the HUD consumes it through the MatchViewModel.
- Kill-feed retention and lobby reset are covered by the dependency-free headless suite.
- LAN peers exchange a protocol version during connection setup and route mismatches through the recovery UI.
- LAN joins have an eight-second timeout that records a diagnostic and returns to the recoverable offline state.
- LAN timeout state reset and diagnostics are covered by the dependency-free headless suite.
- Hitscan damage is routed through a reusable HurtboxComponent signal boundary, keeping weapon resolution decoupled from entity health rules.
- Match results now expose an authoritative winner/tie summary through the ViewModel-driven HUD.
- Match lifecycle state, score snapshots, timers, and result summaries replicate from the host to every LAN client.
- Host health changes replicate through the player boundary so remote health bars remain consistent.
- Health snapshot presentation accepts only the server-side execution path and ignores client-originated calls.
- Player snapshots, combat effects, and respawn visuals use guarded server-originated transport paths.
- Arena spawn and respawn positions are supplied by `ArenaDefinition` and rejected when outside playable bounds.
- Arena platform collision shapes are generated from `ArenaDefinition`, preventing visual and gameplay geometry drift.
- Lobby address validation rejects malformed LAN IPv4 input before opening ENet transport.
- Late-joining LAN peers receive a current authoritative match snapshot before presenting gameplay state.
- Grenade damage, radius, and cooldown use the validated `WeaponDefinition` Resource instead of entity magic numbers.
- Grenade requests now use a host-authoritative fuse before area damage and impact presentation resolve.
- Grenade fuse progress is broadcast as presentation-only feedback before the authoritative blast.
- Delayed client snapshots use a bounded queue and discard stale entries under sustained latency.
- Touch controls are state-aware and do not obscure lobby or results presentation.
- A checked-in PowerShell validation harness parser-checks all project scripts before running core smoke tests.
- The headless suite includes a 1,000-packet deterministic network-soak assertion for configured loss and latency envelopes.
- Player nameplates are presentation-only and derive identity from multiplayer authority, keeping LAN matches readable without coupling UI to gameplay rules.
- The lobby uses the versioned SaveService to restore the last host IP and persist it after a join attempt.
- Match HUD formatting and commands now pass through a dedicated MatchViewModel boundary rather than binding directly to MatchService.
- The Android Debug preset explicitly enables Internet permission for ENet UDP LAN sessions.
- Touch controls include visible gesture guidance for movement, left-stick jetpack, right-stick aim, tap fire, and grenade.
- Touch control anchors and action regions derive from the live viewport instead of assuming a fixed device resolution.
- Match start now enters a host-authoritative warmup countdown before enabling live scoring.
- Established client sessions route host disconnects through the same ErrorService and lobby recovery path as connection failures.
- New network attempts and explicit reset clear prior diagnostics so the debug surface reports current-session failures.
- Save writes now stage through a backup file and restore it if temporary-file promotion fails.
- LAN address discovery filters to RFC1918 private IPv4 ranges so virtual and link-local adapters are not advertised.
- Lobby controls now reflect session authority and match state, preventing clients from attempting host-only start commands.

Remaining release-gate work includes successful Android APK export and physical device/hotspot testing, profiling/soak execution, and replacing remaining prototype shortcuts with dedicated gameplay systems.

### Milestone 1 — Offline vertical slice

One arena, one player, movement, aiming, one weapon, health, death, respawn, and touch controls.

### Milestone 2 — Local multiplayer foundation

Host/join, lobby, two players, synchronized movement, disconnect handling, and a network debug overlay.

### Milestone 3 — Authoritative combat

Server-side fire validation, projectiles, hit detection, damage, death, respawn, and score replication.

### Milestone 4 — Playable match

Match state machine, timer, score limit, results screen, map resources, and reconnect/error flows.

### Milestone 5 — Production hardening

Resource validation, profiling, soak execution, Android export/device testing, and final gameplay-system replacement.

## 18. Definition of done for the first playable LAN release

- Six devices can join the same mobile hotspot.
- A host can create a match and display its local IP.
- Clients can join without editing project files.
- Movement is responsive and remote players interpolate smoothly.
- Combat results are decided by the host.
- A disconnected player is removed safely.
- Match results are consistent for all players.
- Network errors provide a recovery path.
- Content and balance can be changed through Resources.
- UI is not coupled directly to gameplay implementation.
- Debug tools can reproduce latency and packet loss.
- The project has unit and integration coverage for core rules.
