# TASK_001.md

## Task name

M1 — Player Movement Foundation

## Goal

Implement only the first player-controller milestone: a clean, tunable movement foundation that can be tested in a minimal graybox scene.

This task is complete when the project can be opened and the player can reliably:
- move horizontally;
- accelerate and decelerate;
- turn responsively;
- jump;
- perform variable-height jumps;
- use coyote time;
- use jump buffering;
- fall with a controlled maximum fall speed;
- be observed through a minimal usable camera.

Do not implement combat, dash, enemies, bosses, signature mechanics, skill trees, inventory, production art, or audio in TASK_001.

## Required preparation

Before editing:

1. Read `AGENTS.md`.
2. Detect whether this is a Godot or Unity repository.
3. Read these current v2.0 documents under `/docs`:
   - `01_角色测试场草图_修订版_v2.0.docx`
   - the matching engine implementation document:
     - Godot: `02_Godot_Codex_2D动作原型开发规范_修订版_v2.0.docx`
     - Unity: `02_Unity_Codex_2D动作原型开发规范_修订版_v2.0.docx`
   - `03_2D动作角色Controller详细技术规格_修订版_v2.0.docx`
4. Ignore superseded older documents when they conflict with v2.0.
5. Inspect the existing repository structure and reuse appropriate existing systems rather than duplicating them.

Before writing code, briefly state:
- detected engine;
- relevant files/scenes/components already present;
- planned files to create or modify;
- any specification conflict that needs a documented resolution.

Then proceed with implementation.

## Scope

### 1. Player object / scene

Create or adapt the minimum player structure required by the selected engine.

The implementation must support:
- body collision with World;
- configurable movement values;
- grounded detection;
- horizontal facing/direction;
- camera follow;
- future extension without requiring a full rewrite.

Use simple graybox visuals if no player art exists.

Do not block movement work on animation assets.

### 2. Horizontal movement

Implement horizontal movement using the current Controller specification.

Required behavior:
- configurable maximum horizontal speed;
- configurable ground acceleration;
- configurable ground deceleration;
- responsive direction reversal;
- configurable air control;
- deterministic behavior suitable for tuning.

Do not implement “instant set velocity to max speed” unless the current specification explicitly requires it.

All key values must be easy to edit in the engine inspector/resource/settings system.

### 3. Jump model

Use the v2.0 Controller specification as the authority.

The implementation must support:
- target jump height in DU;
- target time-to-apex;
- derived or otherwise internally consistent gravity and initial jump velocity;
- variable jump height;
- stronger/faster descent behavior where specified;
- maximum fall speed.

Avoid maintaining two independent parameter sets that can contradict each other.

If engine units require conversion from DU, centralize that conversion and document it.

### 4. Coyote time

Implement a configurable coyote-time window.

Expected behavior:
- after walking/running off a ledge, the player may still jump during the configured window;
- once the window expires, the jump must not trigger unless another valid jump condition exists.

Use the v2.0 starting value/range as the initial tuning source.

### 5. Jump buffer

Implement a configurable jump-buffer window.

Expected behavior:
- if jump is pressed slightly before landing, the input is remembered;
- when a valid grounded jump becomes available inside the buffer window, the jump executes;
- expired buffered input must not fire later.

Use the v2.0 starting value/range as the initial tuning source.

### 6. Variable jump

Implement short-hop / full-jump behavior.

Expected behavior:
- holding jump produces the intended full jump;
- releasing jump early reduces upward travel;
- the result must remain compatible with coyote time and jump buffering.

The implementation should be parameterized rather than built from unexplained magic constants.

### 7. Minimal graybox test scene

Create or adapt a minimal M1 test area based on the movement-test portion of the v2.0 test-room document.

It must include enough geometry to test:
- flat-ground acceleration and stopping;
- fast left/right reversal;
- normal jump;
- short jump;
- ledge coyote jump;
- buffered landing jump;
- at least one comfortable platform jump;
- at least one near-limit platform jump;
- falling and maximum-fall-speed behavior.

Do not build the complete combat/hazard/prototype zones yet unless they already exist.

Graybox geometry is sufficient.

### 8. Camera

Implement only the minimum camera behavior necessary for M1.

Required:
- player follow;
- stable framing during normal running/jumping;
- no excessive jitter.

Do not implement cinematic boss cameras or elaborate camera effects.

## Initial tuning intent

Use the v2.0 Controller/Test Room documents as the source of truth for exact current starting values.

The tuning intent is:
- fast and precise response;
- slightly more weight than an ultra-light platform character;
- responsive turning;
- predictable aerial correction;
- clear jump apex;
- decisive descent.

These are starting values, not final game-balance guarantees.

Do not claim final feel quality without a human playtest.

## Non-goals

TASK_001 must not add:
- normal attacks;
- air attacks;
- hitboxes/hurtboxes beyond placeholders strictly required by an existing architecture;
- damage;
- health gameplay;
- dash;
- i-frames;
- enemies;
- enemy AI;
- boss systems;
- hazards;
- checkpoints;
- resonance/signature mechanics;
- skill progression;
- save systems;
- final animation content;
- final VFX/SFX;
- UI beyond essential debug information.

If one of these already exists in the project, do not expand it as part of this task.

## Programmatic acceptance criteria

The task should satisfy all applicable checks for the selected engine:

- project files remain syntactically valid;
- no newly introduced compile/script errors;
- player movement code is not a single unmaintainable catch-all implementation;
- core movement parameters are externally tunable;
- coyote time and jump buffer have explicit timers/state rather than accidental side effects;
- jump calculations are internally consistent;
- the player cannot repeatedly gain unintended jumps while airborne;
- maximum fall speed is enforced;
- camera follows the player;
- test geometry can be used to exercise all M1 behaviors.

Run whatever safe automated/editor checks are available in the environment.

If the engine executable/editor is unavailable, do not fabricate results.

## Manual playtest checklist

The human tester should verify:
- holding left/right reaches the intended speed smoothly;
- releasing input produces controlled deceleration;
- reversing direction feels immediate enough without teleport-like velocity snapping;
- short tap jump is visibly lower than held jump;
- walking off an edge and pressing jump just afterward succeeds inside the coyote window;
- pressing jump just before landing triggers a jump on landing inside the buffer window;
- stale buffered inputs do not trigger unexpectedly;
- the jump apex is easy to read;
- descent is not floaty;
- air steering is useful but does not erase jump commitment;
- repeated movement for several minutes does not expose obvious controller glitches;
- camera motion remains stable.

Record subjective feedback separately from code correctness.

## Stop condition

When M1 satisfies the programmatic criteria and is ready for manual playtesting:

STOP.

Do not begin M2.

Do not add basic attack, dummy targets, hit stop, or combat systems unless a later task explicitly requests them.

## Required completion report

When finished, provide:
1. detected engine;
2. summary of implemented M1 behavior;
3. files created/modified;
4. where movement parameters are configured;
5. any DU-to-engine-unit conversion used;
6. tests/checks actually run;
7. exact manual playtest steps;
8. known issues/limitations;
9. recommendation for M1 tuning before M2.

Do not present M2 implementation as part of TASK_001.
