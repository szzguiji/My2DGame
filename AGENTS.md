# AGENTS.md

## Project purpose

This repository is a graybox prototype for a high-quality 2D side-scrolling action game.

The current goal is not to build the full game. The goal is to establish a stable, tunable player-controller foundation and validate game feel through short milestones.

Codex should act as an implementation engineer. Do not invent major game-design decisions when the design documents already specify them.

## Source-of-truth documents

Before making gameplay changes, read the design documents under `/docs`.

Use these documents in this precedence order:

1. `03_2D动作角色Controller详细技术规格_修订版_v2.0.docx`
   - Highest authority for player-controller behavior, action rules, state priority, tuning parameters, and acceptance criteria.

2. The engine-specific implementation document:
   - Godot: `02_Godot_Codex_2D动作原型开发规范_修订版_v2.0.docx`
   - Unity: `02_Unity_Codex_2D动作原型开发规范_修订版_v2.0.docx`
   - Highest authority for engine architecture, scene/component structure, collision layers, and engine-specific implementation choices.

3. `01_角色测试场草图_修订版_v2.0.docx`
   - Authority for graybox test-room layout, test zones, milestone order, and manual playtest goals.

If an older document conflicts with a v2.0 document, v2.0 wins.

Do not use superseded/older prototype documents as authoritative specifications.

If two current v2.0 documents appear to conflict:
- do not silently choose one;
- identify the conflict;
- prefer the more specific document according to the precedence above;
- report the decision in the completion summary.

## Engine detection

Determine the engine from the repository before editing.

### Godot project
Treat the project as Godot when the repository contains `project.godot`.

Use the Godot v2.0 implementation document and ignore the Unity implementation document.

### Unity project
Treat the project as Unity when the repository contains `Assets/`, `Packages/`, and `ProjectSettings/`.

Use the Unity v2.0 implementation document and ignore the Godot implementation document.

### Ambiguous repository
If both engine signatures exist, or neither exists, stop before implementing gameplay code and report the ambiguity.

Do not create a second engine implementation inside the same project.

## Core development principles

- Keep the project runnable after every task.
- Implement only the requested milestone.
- Do not add future mechanics “for completeness”.
- Prefer small, clear modules over large all-purpose scripts.
- Keep gameplay tuning data easy to edit.
- Avoid unnecessary abstraction before a second real use case exists.
- Separate gameplay logic from presentation where practical.
- Do not make animation events the sole authority for gameplay timing.
- Hitboxes/Hurtboxes must not create unintended body physics.
- Never mix 3D components into this 2D prototype unless explicitly requested.
- Do not introduce production art requirements into graybox milestones.
- Do not rewrite design documents unless explicitly asked.
- Do not replace player-facing design decisions with personal preference.

## Design-unit rule

The design documents use design units (DU) as the shared gameplay-space reference.

Do not hard-code unrelated pixel values in gameplay logic when a DU-based value is specified.

Engine-specific conversion should be centralized and documented.

Jump behavior should be driven by the design parameters from the Controller specification, especially:
- jump height;
- time to apex;
- fall multiplier;
- coyote time;
- jump buffer.

When practical, derive gravity and initial jump velocity from jump height and time-to-apex instead of maintaining contradictory independent values.

## Player architecture expectations

Player behavior should remain modular.

The exact file/class names may follow the engine-specific document, but responsibilities should remain separated conceptually:

- locomotion / movement;
- player action coordination;
- combat;
- health / damage;
- animation / presentation;
- tunable settings/data.

Do not place every feature into one monolithic player script.

The logical state model must support the distinction between:
- locomotion state, such as Grounded / Airborne;
- action state, such as None / Attack / Dash / Hurt / Dead.

Action priority for the prototype follows the current Controller specification. Do not allow lower-priority movement logic to override a higher-priority action.

## Collision policy

Use the collision-layer/mask rules from the engine-specific v2.0 document.

The intended conceptual groups are:
- World
- PlayerBody
- EnemyBody
- PlayerHitbox
- EnemyHitbox
- PlayerHurtbox
- EnemyHurtbox
- Hazard

Key rule:
- hitboxes detect hurtboxes;
- hitboxes are not physical body colliders;
- hurtboxes do not push actors;
- world/body collision remains separate from damage detection.

## Milestone policy

The prototype is developed in milestones:

- M1: movement foundation
- M2: basic attack + dummy + hit feedback
- M3: one basic melee enemy
- M4: dash
- M5: vertical/air combat + flying enemy
- M6: hazards + hurt/reset loop
- M7: signature-mechanic experiments

Do not skip ahead unless the task explicitly says to do so.

A milestone is not complete merely because the code compiles. It must also expose the parameters needed for manual tuning and provide a simple way to test the behavior in the graybox scene.

## Validation expectations

For each task:

1. Inspect the existing project before editing.
2. State which files/components are expected to change.
3. Implement the smallest complete version of the requested milestone.
4. Run available automated/editor-safe validation.
5. Fix errors introduced by the change.
6. Do not claim subjective game feel is “good” without human playtesting.
7. Report which acceptance criteria are machine-verifiable and which require manual playtesting.

When engine/editor execution is unavailable, say so clearly and provide exact manual test steps.

## Completion report format

At the end of a task, report:

1. What was implemented.
2. Files created or modified.
3. Important architectural decisions.
4. Tests/checks actually run and their results.
5. Manual playtest steps.
6. Known limitations or unresolved issues.
7. What should be done next — but do not implement the next milestone unless asked.

Keep this report concise and factual.
