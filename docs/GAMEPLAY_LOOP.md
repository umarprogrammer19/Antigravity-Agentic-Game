# DungeonMind — Gameplay Loop Document
### Reference for: Flutter Architect Agent, Flame Game Engine, AI Behavior Specs
---

## OVERVIEW

DungeonMind is a **turn-based roguelike dungeon crawler**.
Every action the player takes costs 1 turn. After each player turn, ALL enemies take 1 turn.
The game is grid-based (tile map). Player and enemies occupy exactly 1 tile at a time.

There are NO timers, NO real-time pressure. The player can think as long as they want.
This makes AI latency invisible — enemy "thinking" feels natural.

---

## GRID SYSTEM

### Tile Types
```
0 = WALL       → Black/dark gray. Cannot be entered. Blocks line of sight.
1 = FLOOR      → Brown/tan. Walkable. Default dungeon tile.
2 = EXIT       → Green glowing tile. Player steps on it to clear the floor.
3 = LAVA       → Orange/red. Walkable but deals 5 damage per step (volcanic theme).
4 = TRAP       → Hidden (looks like floor). Triggers when stepped on → 15 damage.
5 = ITEM       → Gold highlight. Collect by stepping on it.
```

### Grid Size
- Minimum: 10×10
- Standard: 15×15
- Maximum: 20×20
- All grids are rectangular

### Coordinate System
```
[row][col] where [0][0] = TOP-LEFT
Increasing row = moving DOWN
Increasing col = moving RIGHT

Example 10×10 grid positions:
  [0][0] = top-left corner
  [9][9] = bottom-right corner
  [0][9] = top-right corner
  [9][0] = bottom-left corner
```

### Movement Rules
- Player moves 1 tile per turn (orthogonal: up/down/left/right)
- Diagonal movement: NOT allowed
- Cannot move into WALL tiles
- Moving into a tile occupied by an enemy = ATTACK (not movement)
- Moving into EXIT tile = floor cleared

---

## CHARACTER SYSTEM

### Classes
```
WARRIOR
  HP: 150
  Attack: 20
  Defense: 8
  Move Range: 1 tile
  Special: Melee attacks deal +50% damage (20 × 1.5 = 30 effective)
  Weakness: No ranged attacks. Must step adjacent to attack.

MAGE
  HP: 80
  Attack: 35
  Defense: 3
  Move Range: 1 tile
  Special: Can attack enemies UP TO 2 tiles away (no need to be adjacent).
           Attack is a bolt: choose direction, hits first enemy in line.
  Weakness: Low HP. Dies fast if enemies reach it.

RANGER
  HP: 100
  Attack: 25
  Defense: 5
  Move Range: 1 tile (but can also DASH: move 2 tiles at once, once per floor)
  Special: Ranged attack (1 tile range diagonal allowed for Ranger only)
  Weakness: Medium everything. No standout strength.
```

### Player State (tracked per session)
```json
{
  "class": "warrior",
  "max_hp": 150,
  "current_hp": 150,
  "attack": 20,
  "defense": 8,
  "position": [3, 4],
  "inventory": [],
  "floors_cleared": 0,
  "enemies_killed": 0,
  "turn_count": 0,
  "special_used": false
}
```

---

## COMBAT SYSTEM

### Melee Attack
Triggered when player moves into enemy tile OR enemy moves into player tile.
```
damage = max(1, attacker_attack - defender_defense)

Example:
  Player attack=20, Enemy defense=5
  damage = max(1, 20 - 5) = 15 HP removed from enemy
```

### Ranged Attack (Mage / Ranger special)
Triggered by separate action (not movement).
```
Mage bolt: Select direction → damages first enemy in that line up to 2 tiles
Ranger shot: Select adjacent or diagonal enemy → direct damage
Same damage formula: max(1, attacker_attack - defender_defense)
```

### Item Effects
```
HEALTH_POTION: Restore 30 HP (capped at max_hp). Auto-collected on tile entry.
DAMAGE_BOOST: +10 attack for remainder of floor. Auto-collected.
SHIELD: +5 defense for remainder of floor. Auto-collected.
```

### Death
```
If player.current_hp <= 0:
  → Show death screen
  → Record session result (won=false)
  → Show AI feedback
  → Update Firestore

If enemy.hp <= 0:
  → Remove enemy from grid
  → Grant XP: floor(enemy.max_hp / 5)
  → Update enemies_killed counter
```

---

## TURN STRUCTURE

### Player Turn
```
1. Player inputs action (move / attack / use special / wait)
2. Action validated by RefereeAgent (or local rule check for standard moves)
3. Action result applied:
   - If move: update player position
   - If attack: compute + apply damage
   - If special: apply class ability
   - If wait: no change (skip turn)
4. Check win/lose conditions
5. If alive + not at exit: proceed to Enemy Turn
```

### Enemy Turn (PER ENEMY, IN ORDER)
```
For each enemy (in order of enemy ID):
  1. Call RivalAgent.getNPCDecision(enemy_id, board_state, player_last_moves)
  2. Receive action: {type, target}
  3. Apply action:
     - If "move": move enemy 1 tile toward target
     - If "attack": compute damage to player
     - If "wait": no action
  4. Update board state
5. After ALL enemies have taken turn → next player turn
```

### Turn Display
```
HUD shows:
  "Turn 14 — YOUR MOVE"     ← during player turn
  "Turn 14 — ENEMY THINKING..." ← during AI processing
  "Turn 14 — ENEMY MOVING"  ← during enemy animation
```

---

## FLOOR SYSTEM

### Floor Progression
```
Session starts at Floor 1.
Player clears Floor 1 (reaches exit) → AI generates Floor 2.
Floors increase in difficulty as they go up.
Session ends when: player dies OR player clears Floor 5 (session win).
```

### Difficulty Scaling Per Floor
```
Floor 1: base difficulty from DungeonMasterAgent
Floor 2: difficulty + 1
Floor 3: difficulty + 2
Floor 4: difficulty + 3
Floor 5: difficulty + 4 (BOSS FLOOR — one boss enemy + regular enemies)
```

### Floor Generation Trigger
```
When player steps on EXIT tile:
  → Save floor stats to Firestore
  → Show "Floor Cleared!" screen (2 seconds)
  → Display AI-generated narrative text (NarrativeAgent)
  → Call LevelGeneratorAgent for next floor
  → Show "The dungeon shifts..." loading screen
  → Render new floor
```

---

## ENEMY SYSTEM

### Enemy Types Per Theme

**Cursed Library Theme:**
```
SHADOW_MAGE: hp=30, attack=12, defense=2, behavior=ranged_2tile
BOOK_GOLEM:  hp=60, attack=8,  defense=15, behavior=tank_melee
LIBRARIAN:   hp=20, attack=15, defense=0,  behavior=flee_then_attack
```

**Volcanic Caves Theme:**
```
FIRE_ELEMENTAL: hp=25, attack=18, defense=0, behavior=rush_melee
ROCK_TROLL:     hp=80, attack=10, defense=20, behavior=slow_tank
LAVA_SPRITE:    hp=15, attack=22, defense=0, behavior=hit_and_run
```

**Enchanted Forest Theme:**
```
GOBLIN:        hp=20, attack=8,  defense=3, behavior=swarm_melee
FOREST_WITCH:  hp=35, attack=14, defense=4, behavior=ranged_2tile
DRUID:         hp=50, attack=6,  defense=8, behavior=heals_nearby_enemies
```

### Enemy Behavior Types (Base Behavior — Before AI Override)
```
rush_melee:        Move toward player every turn. Attack if adjacent.
ranged_2tile:      Stay 2 tiles away. Attack from distance.
tank_melee:        Move toward player slowly. High defense.
flee_then_attack:  Move away if player is adjacent. Attack from 2 tiles.
slow_tank:         Move 1 tile every 2 turns. High HP.
hit_and_run:       Attack if adjacent, then move away.
swarm_melee:       Move toward player. 3x more likely to spawn in groups.
heals_nearby:      Move toward injured allies. Restore 5HP per turn to adjacent.
```

### Enemy AI Adaptation (RivalAgent)
After 3 turns, RivalAgent reads player's pattern and OVERRIDES base behavior:
```
If player always attacks melee → switch to ranged_2tile
If player always uses ranged → rush_melee (close the gap)
If player runs away → advance aggressively, cut off escape route
If player waits → advance and attack
```

---

## ITEM SYSTEM

### Item Placement
- 1-3 items per floor (based on difficulty — harder = more items)
- Placed randomly on floor tiles, never on player start, enemy spawn, or exit

### Item Collection
- Automatic on tile entry (no separate "pick up" action needed)
- Shows short text: "You found a Health Potion! +30 HP"
- NarrativeAgent generates flavor text for special items on boss floor

---

## WIN/LOSE SYSTEM

### Session Win
```
Trigger: Player clears Floor 5
Score = (floors_cleared × 100) + (current_hp × 2) + (enemies_killed × 10)
Show: Victory screen, score, AI session summary
Save: Firestore session record (won=true)
Update: Leaderboard
```

### Session Loss (Death)
```
Trigger: player.current_hp <= 0
Show: Death screen with cause (which enemy type killed you)
AI Feedback: DungeonMasterAgent generates feedback:
  "You died because: [reason]"
  "Next time try: [recommendation]"
  "Adapted difficulty: [what will be easier next time]"
Save: Firestore session record (won=false, death_cause, floor_reached)
```

### Early Exit
```
Player can tap MENU button any time.
Confirm dialog: "Abandon this run? Your progress will be lost."
If confirmed: save partial session, return to menu.
```

---

## SCORING SYSTEM

### Score Breakdown
```
Base:     floors_cleared × 100
Survival: remaining_hp × 2
Combat:   enemies_killed × 10
Speed:    if session_turns < 50 → bonus +200
Class:    Mage bonus × 1.5 (harder class)
```

### Leaderboard
- Top 10 scores per player (personal best)
- Global top 20 (all players)
- Shows: rank, name, score, class used, floors cleared

---

## UI FEEDBACK DURING GAMEPLAY

### HUD Elements (always visible)
```
TOP-LEFT:  HP bar (red fill) + numeric "HP: 85/150"
TOP-RIGHT: Floor number "Floor 3/5" + Turn count "Turn 22"
BOTTOM:    AI Decision Panel (collapsible, 60px collapsed)
```

### AI Decision Panel States
```
COLLAPSED (default):
  Shows: "🧠 [Last agent]: [short decision summary]"
  Example: "🧠 Rival: Shadow Mage switched to ranged tactics"

EXPANDED (user drags up):
  Shows: Last 10 trace entries as cards
  Each card: Agent icon | Reasoning | Timestamp
  Scrollable list

THINKING (during AI call):
  Shows pulsing animation: "🧠 AI THINKING..."
  Panel turns slightly brighter
```

### Combat Feedback
```
Damage dealt: Red floating text "-15" rises from enemy
Damage taken: Player tile flashes red briefly  
Enemy death: Enemy tile fades out + "💀" briefly
Item collected: Gold floating text appears
```

---

*Agents reading this: implement EXACTLY this turn structure. Do not invent new rules.*
*All combat math uses the formulas above. Do not modify them.*
