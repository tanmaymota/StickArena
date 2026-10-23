# Stick Arena

A small 2D fighting game prototype made with Godot 4.7. It is a school-project-sized game focused on local matches, a CPU opponent, and a practice mode.

## Features

- 1 Player versus CPU, 2 Player, and Practice modes
- Easy, Normal, and Hard CPU difficulty
- Two stages, including an Arena 2 lava hazard
- Punching, blocking, a bat pickup, and super projectiles
- Best-of-three rounds with a 60-second timer in normal matches
- Practice dummy, damage numbers, and health recovery after a KO
- Main menu, settings, controls screen, and pause menu

## Run the game

1. Install Godot 4.7 or a compatible Godot 4.x release.
2. In Godot Project Manager, choose **Import** and select this folder's `project.godot` file.
3. Open the project and press **F6** to run the main scene, or **F5** to run the project.

The project uses Godot's GL Compatibility renderer and does not require external art assets.

## Play in a browser

The project includes a Web export preset and a GitHub Actions workflow that builds the browser version and publishes the `web/` landing page to GitHub Pages after changes are pushed to `main`. Once Pages is enabled for the repository and the first deployment completes, players can open the site URL and play without installing Godot.

The web build runs locally in each player's browser; it does not add online multiplayer. Browser audio may require one click or key press before sound is allowed.

## Controls

| Action | Player 1 | Player 2 |
|---|---|---|
| Move | A / D | Left / Right |
| Jump | W or Space | Up |
| Attack | F | O |
| Block | S | Down |
| Special | G | P |

Menus use Up/Down and Enter. Use Left/Right to change settings or stages, Esc to go back or pause, and R to restart. In Practice, M fills Player 1's super meter.

## Project layout

- `scenes/game/main.tscn` - main game scene and HUD
- `scenes/arenas/arena.tscn` - stage environment
- `scenes/player/fighter.tscn` - fighter placeholder art and collision body
- `scripts/game/main.gd` - menus, match flow, CPU, stages, weapons, timer, and effects
- `scripts/player/fighter.gd` - movement and fighter combat
- `tests/runtime_smoke.gd` - headless gameplay smoke checks

## Presentation documents

- `docs/Stick_Arena_Architecture_Deep_Dive.pdf` - 60-page frontend and backend architecture guide with detailed diagrams.
- `docs/Stick_Arena_Project_Report.pdf` - 26-page project report: development scope, all major requested features, prompt history, testing summary, and presentation guide.

## Test status

The recorded Godot 4.7.2 headless smoke run on October 9, 2026 completed **40 checks with 0 failures**. The main scene also launched for 90 frames without scene or script errors. This headless run does not verify physical keyboard play, rendered visuals, or audible sound; those manual checks and their expected outcomes are summarized in the Project Report.

## About

Stick Arena is a learning prototype. Gameplay and visuals are still being refined; all fighter art is currently made from simple shapes and lines.
