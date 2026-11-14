# Bounce Back

A small neon brick breaker built with Godot 4. The visuals are drawn in
code and the sound effects are generated WAV files, so there are no
external art assets.

## Play

1. Install Godot 4.2 or newer (developed with 4.7.2).
2. Import `project.godot` in the Godot project manager.
3. Press F5.

Or from a terminal:

```sh
godot --path .
```

## Controls

| Action | Keys |
| --- | --- |
| Move paddle | Mouse, A/D, or left/right arrows |
| Launch ball | Space or left click |
| Pause | Esc |
| Mute | M |

## Features

- Five brick layouts that cycle forever with increasing brick health
- Bricks with 1 to 4 hit points, each color worth different points
- Combo multiplier up to x5 for breaking bricks without touching the paddle
- Wide paddle, multi-ball, slow motion, shield, and extra life power-ups
- Floating score popups, particles, ball trail, and camera shake
- Pause menu, game over screen, and a high score saved between runs

## Scoring

| Brick | Hits | Points |
| --- | --- | --- |
| Red | 1 | 60 |
| Orange | 2 | 120 |
| Purple | 3 | 200 |
| Blue | 4 | 300 |

Each brick destroyed without touching the paddle raises the combo. Points
are multiplied by the combo up to x5. Touching the paddle or losing a ball
resets it. Clearing a level gives 500 + 100 per level.

## Power-ups

Catch the falling circles with the paddle for 150 bonus points.

| Letter | Effect |
| --- | --- |
| W | Wide paddle for 12 seconds |
| M | Multi-ball, up to 9 balls |
| S | Slow motion for 8 seconds |
| B | Shield that saves the ball once |
| + | Extra life (max 5) |

## Project layout

```
project.godot      project file
scenes/            menu, gameplay, paddle, ball, brick, power-up, burst
scripts/           game code; game.gd is the main file
assets/sounds/     generated sound effects
ui/theme.tres      shared button styling
icon.svg           project icon
```

## Tweaking

- Ball speed, lives, and brick layouts: constants in `scripts/game.gd`
- Paddle speed: `SPEED` in `scripts/paddle.gd`
- Power-up fall speed: `fall_speed` in `scripts/power_up.gd`

## License

MIT, see [LICENSE](LICENSE).
