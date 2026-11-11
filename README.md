# N-vs-Z

An original side-view gate battle. Choose six soldiers, hold your clan gate, and break the cursed gate. It is inspired by the march-and-defend battles of Samurai vs Zombies Defense. It is not affiliated with Glu, and it does not use that game's art or code.

## Play

Install [Godot 4.7](https://godotengine.org/) or newer, open this folder as a project, and press F5.

From a terminal, if `godot` is on your PATH:

```
godot --path .
```

## Controls

- Drag the road, or use WASD / arrow keys, to move the hero.
- Sword: the red button, or J.
- Shoot: the indigo button, or K.
- Call a soldier with the buttons on the bottom left, or keys 1–6 in the order you chose them. Hold a button to call that soldier again when the timer and the value allow it.
- Escape pauses.

Soldiers only march forward. If something gets behind them, run the hero back. Your gate and the cursed gate each have 1000 blood.

## The six

There are 11 soldiers. Each battle uses 6.

| Soldier | Value | Call time | Blood | What they do |
| --- | --- | --- | --- | --- |
| Sword Soldier | 5 | 3s | 100 | 20 damage every second, short reach, one target |
| Archer | 10 | 5s | 80 | 40 damage every second, long reach, one target |
| Shield-Bearer | 10 | 5s | 200 | 15 damage every second, short reach, one target |
| Saber | 25 | 10s | 150 | 50 damage every second, short reach, one target |
| Lancer | 20 | 5s | 100 | 20 damage every second, mid reach, one target |
| Berserker | 50 | 20s | 300 | 80 damage every 3 seconds to everyone in short range |
| Horse Rider | 20 | 10s | 100 | Fast. 30 damage every second, one target |
| Suicide Squad | 20 | 10s | 40 | Blasts everyone in short range for 100, and loses 40 blood |
| Assassin | 15 | 8s | 100 | Blinks behind the first enemy who could hit her, once, then cuts for 50 |
| Healing Caster | 20 | 10s | 50 | Heals the most wounded ally in front for 40 blood each second |
| Leveling Caster | 20 | 10s | 50 | Gives the highest-damage ally in front +20% damage and +20% blood |

Soldiers shoot enemies at their own range. A gate is only hurt by someone who has walked up to it, so bows do not burn it from the back of the road.
