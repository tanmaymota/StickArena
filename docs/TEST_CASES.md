# Stick Arena — Manual Test Cases

This is a manual regression checklist for the current Godot project. Run it in Godot 4.7 with the project’s GL Compatibility renderer. The cases cover normal matches and Practice Mode; Practice-only behavior must not leak into normal matches.

**Test run:** 2026-10-09  **Tester:** Codex (headless)  **Build:** Godot 4.7.2 stable

For actual play tests, record **Pass**, **Fail**, or **Blocked** and add a short note or screenshot path. “Source match” means the expected code path/value was found; it is not a runtime pass.

**Runtime run (2026-10-09):** Godot 4.7.2 headless smoke harness: **40 passed, 0 failed**. A fresh 90-frame launch of the main scene also exited with code 0 and no scene/script errors. Godot emitted an environment error reading the Windows root-certificate store; it did not stop either run. The harness calls menu handlers and gameplay methods directly, so it does not replace physical keyboard or visual/audio testing.

During an earlier expanded run, pause emitted a script error because its effects loop treated every child (including damage-number labels) as particles. That was fixed; the latest run has no script errors and **40/40 passed**. A first check of the new projectile trail assertion looked for a fixed child name; Godot auto-names the node differently, so the test was corrected to check its particle-node type.

To repeat the automated smoke checks, run `Godot_v4.7.2-stable_win64.exe --headless --path <project-folder> --script res://tests/runtime_smoke.gd`.

| ID | Source review | Runtime result | Evidence / notes |
|---|---|---|---|
| MENU-01 | Source match | Partial pass | Headless test confirmed launch menu and Play handler; physical navigation/Esc not tested. |
| MENU-02 | Source match | Partial pass | Headless test confirmed Practice → dummy → stage flow and stage toggle; CPU difficulty/keyboard navigation not tested. |
| MENU-03 | Source match | Not run | Settings audio and navigation require interactive verification. |
| MATCH-01 | Source match | Not run | Movement/collision behavior not covered by this harness. |
| MATCH-02 | Source match | Partial pass | Runtime verified 20-damage punch, damage label, and cooldown; range/facing not tested. |
| MATCH-03 | Source match | Pass | Runtime verified 5 chip damage and zero knockback on block. |
| MATCH-04 | Source match | Partial pass | Runtime verified equip/hide state, 35-damage armed attack, and disarm/drop on hit; physical pickup overlap, swing range, and dropped-weapon recollection not exercised. |
| MATCH-05 | Source match | Partial pass | Runtime verified 40/10 damage, full-meter firing, meter consumption, particle trail, and one-active-blast rule; physical key input, collision impact, and sound/visual quality not exercised. |
| MATCH-06 | Source match | Partial pass | Runtime verified timeout, equal-health draw, and higher-health winner; full countdown/red pulse/TIME! duration not exercised. |
| MATCH-07 | Source match | Pass | Runtime verified two round wins reach the match-end state. |
| MATCH-08 | Source match | Partial pass | Runtime verified pause/resume states; menu key navigation not tested. |
| STAGE-01 | Source match | Not run | Arena 1 visual/boundary behavior not exercised. |
| STAGE-02 | Source match | Partial pass | Runtime verified lava tick damage, Arena 2 physics toggle, and weapon loss into lava schedules respawn; actual pit movement, repeated interval, ember visuals, and respawn completion not exercised. |
| CPU-01 | Source match | Partial pass | Runtime verified CPU edge steering avoids walking off Arena 2’s platform; randomized combat, difficulty, weapon seeking, and CPU super timing need a live match test. |
| PRACTICE-01 | Source match | Partial pass | Runtime verified Practice → dummy → stage selection handler path; CPU difficulty selection not tested. |
| PRACTICE-02 | Source match | Pass | Runtime verified hidden timer, stopped timer, and no round win on KO. |
| PRACTICE-03 | Source match | Pass | Runtime verified dummy movement direction is zero and attack input is disabled. |
| PRACTICE-04 | Source match | Not run | Headless input injection cannot verify a physical M keypress; meter-key behavior remains unverified. P2’s N key is not reachable in the current CPU/dummy-only Practice choices. |
| PRACTICE-05 | Source match | Pass | Runtime verified KO schedules 1-second recovery and restores full health without ending Practice. |
| PRACTICE-06 | Source match | Partial pass | Runtime verified -20 punch and -10 lava damage labels; other labels were not checked. |
| PRACTICE-07 | Source match | Not run | Pause/resume/restart navigation needs live input. |
| VISUAL-01 | Partial | Not run | Effects are present in source, but visuals and audio need in-game review. |

## Controls reference

- Menus: Up/Down to navigate, Enter to confirm, Left/Right for settings and stage selection, Esc to go back or pause, R to restart.
- Player 1: A/D move, W or Space jump, F attack, S block, G special.
- Player 2: Left/Right move, Up jump, O attack, Down block, P special.
- Practice only: M fills Player 1’s super meter. N is assigned to Player 2 only when Player 2 is human-controlled; current Practice choices use a CPU or dummy for Player 2.

## Menu and setup

### MENU-01 — Main menu navigation

**Setup:** Launch the project.

**Steps:** Move through Play, Settings, and Controls with Up/Down. Open each with Enter. Press Esc from Settings and Controls, then press Esc on the main menu.

**Expected:** The main menu appears first; each option opens the right screen; Esc returns from Settings/Controls to the main menu and does nothing at the top level.

### MENU-02 — Mode and stage selection

**Steps:** Choose Play. Visit each mode option, then choose a mode and select Arena 1 or Arena 2 with Left/Right. Press Esc once on stage select and once on mode select.

**Expected:** Mode choices include Easy, Normal, and Hard CPU, 2 Players, and Practice. Stage select offers both arenas. Esc returns to the preceding selection screen.

### MENU-03 — Settings and controls reference

**Steps:** In Settings, change master volume and toggle screen shake. Open Controls and compare the listed keys to the controls reference above.

**Expected:** Volume changes sound-effect level; shake can be disabled/enabled; the reference includes the existing fight keys and practice meter keys.

## Normal match regression

### MATCH-01 — Two-player movement and arena bounds

**Setup:** Start a 2 Players match on Arena 1.

**Steps:** Move both fighters toward each arena edge and toward one another; jump and land.

**Expected:** A/D and Left/Right move the correct fighter; fighters face one another, stay within Arena 1 bounds, and do not walk through each other. Jumping and floor collision work.

### MATCH-02 — Unarmed hit, damage readout, and cooldown

**Steps:** Player 1 lands an unblocked punch on Player 2. Note the health bar/readout. Hold or rapidly tap F.

**Expected:** A normal punch removes 20 health (unless fewer than 20 remain), briefly shows the applied damage above the target, and cannot be spammed faster than the existing ~0.45-second cooldown.

### MATCH-03 — Blocking and chip damage

**Steps:** Player 2 holds Down while Player 1 punches; repeat with Player 1 holding S while Player 2 punches.

**Expected:** Each blocked normal attack removes 5 health, shows “-5,” and causes no hit knockback. Controls work for either player.

### MATCH-04 — Bat pickup, armed attack, and disarm

**Steps:** Walk over the bat. Land an unblocked attack. Then pick it up again and take a hit while holding it.

**Expected:** The floor bat disappears and appears in the holder’s hand; the HUD indicates possession; an unblocked bat hit removes 35 health and has the existing cooldown; a hit (including a blocked hit) drops the bat for either fighter to collect.

### MATCH-05 — Super meter and projectile

**Steps:** Build meter by landing and taking hits. At full meter, use G or P; test one unblocked and one blocked blast. Try to fire a second blast while the first is still on screen.

**Expected:** Meter fills and caps at 100, resets after use, and a fighter has at most one active blast. An unblocked blast removes 40 health; a blocked blast removes 10. Projectile, charge, trail, impact, and distinct fire/hit sounds appear.

### MATCH-06 — Round timer and timeout result

**Setup:** Start a normal match and allow a round to reach zero.

**Expected:** The 60-second countdown starts with FIGHT, pauses with the game, turns red/pulses in the last 10 seconds, and stops at zero. “TIME!” appears briefly; greater remaining health wins. Equal health causes a replayed draw without awarding a round.

### MATCH-07 — Best-of-three and match end

**Steps:** Finish rounds until one fighter wins two.

**Expected:** Round-win indicators update, the match ends at two round wins, a clear winner screen appears, and R reloads to the launch/menu flow so another match can be started. The other player can win the same way.

### MATCH-08 — Pause, resume, restart, and main menu

**Steps:** Press Esc during a match. Try Resume, Restart, and Main Menu.

**Expected:** Pause offers all three options. Resume returns to the match, Restart reloads the game, and Main Menu returns to the top-level menu. Gameplay and timer do not advance while paused.

## Stages and CPU

### STAGE-01 — Arena 1 has no lava hazard

**Setup:** Play a normal match on Arena 1.

**Steps:** Move or knock a fighter near either side of the stage and observe the floor.

**Expected:** Arena 1 retains its full-width floor and boundary behavior; there is no lava damage or lava weapon loss.

### STAGE-02 — Arena 2 lava and weapon respawn

**Setup:** Play on Arena 2.

**Steps:** Move/knock a fighter beyond the central safe platform. Drop or knock the bat into a lava pit and wait.

**Expected:** The distinct lava stage has a central safe platform and glowing pits. A fighter over lava takes 10 damage about every 0.5 seconds with upward/inward recoil and can return to safety. A bat lost in lava disappears and respawns on the safe platform after a delay.

### CPU-01 — CPU difficulty and special use

**Setup:** Play one round at Easy, Normal, then Hard; build the CPU’s meter during play.

**Expected:** The opponent is labeled CPU, behaves within the selected difficulty (Easy less frequent/slower reactions; Hard more frequent/faster), pursues weapons when appropriate, and uses a full super meter at mid-to-long range. CPU uses the same combat damage, blocking, and cooldown rules.

## Practice Mode

### PRACTICE-01 — Practice mode and opponent selection

**Steps:** Choose Practice. Select each CPU difficulty and Passive Dummy, then select each arena.

**Expected:** Practice is available from mode select; CPU difficulty and Passive Dummy are selectable; Arena 1 and Arena 2 both start correctly. CPU selection shows CPU on the HUD; dummy selection shows DUMMY.

### PRACTICE-02 — No round timer or round/match win

**Setup:** Start Practice against the dummy.

**Steps:** Observe the top-center timer area and continue until either fighter reaches zero health.

**Expected:** No countdown is shown; the match does not announce a round winner or end. Each KO recovers instead of counting toward a match win.

### PRACTICE-03 — Passive dummy behavior

**Steps:** Start Practice against Passive Dummy. Wait, then attack, block, and knock the dummy back.

**Expected:** The dummy does not walk or attack on its own; it can be hit and knocked around. The human fighter’s controls still work.

### PRACTICE-04 — Manual super-meter fill

**Steps:** Press M during an active Practice bout; in a 2-player Practice bout, press N as well. Repeat the same keys in a normal match.

**Expected:** M fills Player 1’s meter and N fills Player 2’s meter to full in Practice only. They do not manually fill meter in normal matches. Full-meter fighters can use their usual special key.

### PRACTICE-05 — Recovery after lethal damage

**Steps:** Allow each fighter’s health to reach zero. Time the recovery; repeat on Arena 2 by being knocked into lava.

**Expected:** The fighter returns to full health about one second after KO, the bout continues without a winner, and a fighter lost in Arena 2 lava returns to a safe platform on recovery.

### PRACTICE-06 — Damage numbers show applied damage

**Steps:** Cause an unblocked punch, blocked punch, bat hit, unblocked special, blocked special, and (on Arena 2) lava tick. Include a hit when the target has less health remaining than the attack’s nominal damage.

**Expected:** A brief number appears above the target for each hit: normally 20, 5, 35, 40, 10, and 10 respectively. If less health remains, the number reflects health actually removed rather than exceeding the remaining health.

### PRACTICE-07 — Pause and restart behavior

**Steps:** Pause a Practice bout with Esc. Wait, resume, then pause and select Restart and Main Menu in separate attempts.

**Expected:** The normal pause screen works in Practice; combat and recovery timers pause; Resume continues Practice; Restart and Main Menu behave as in normal matches.

## Visual and audio smoke test

### VISUAL-01 — Feedback and presentation

**Steps:** During both arenas, move, jump, land hits, block, fire/hit with a special, and finish a round in a normal match.

**Expected:** Health/super bars, weapon indicator, hit flash, hit shake/tint, sparks, movement/landing dust, KO effect, background/floor details, and hit/round-end/special sounds appear without obstructing play. Settings volume and screen-shake toggle affect their respective effects.
