# TransmuteTimer

A tiny World of Warcraft Classic Era addon for alchemists. Shows your shared transmute cooldown on screen and lets you craft any transmute with one click.

## What it does

- **Live countdown** — a small box on your screen shows time remaining until your next transmute is ready (`Xd Yh` / `Hh Mm` / `Mm Ss`)
- **Click to craft** — when ready, the box turns green and says "Click to Transmute". Left-click and it crafts immediately, no profession window dance
- **All 12 transmutes supported** — bars (Gold, Truesilver, Arcanite), all elemental essences (Air, Fire, Earth, Water, Life, Undeath), and Elemental Fire
- **Pick your transmute** — right-click the button to choose which one you want to craft. Each shows the icon of the result item
- **Movable** — shift + left-click and drag to put it wherever you want

## Install

1. Download or clone this repo
2. Drop the `TransmuteTimer` folder into `World of Warcraft/_classic_era_/Interface/AddOns/`
3. Restart the game (or `/reload`)

## Slash commands

- `/tmt` — toggle visibility
- `/tmt reset` — recenter the box

## Notes

- The cooldown is shared across all transmutes, so the timer is the same regardless of which one you have selected
- Transmutes that your character hasn't learned appear in the dropdown as `(not learned)` and can't be selected
- Requires the Philosopher's Stone in your bags (like all transmutes)
