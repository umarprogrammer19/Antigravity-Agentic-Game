# DungeonMind — Quick Reference Card
### Everything in one place. Print this. Keep it open always.
---

## THE GAME IN 3 LINES
Turn-based roguelike dungeon crawler.
5 Gemini AI agents generate levels, control enemies, tell stories, validate actions, and adapt to you.
Every decision they make is shown live on screen.

---

## PROJECT STRUCTURE

```
antigravity-game/
├── mobile-game/           → Flutter app (Dart)
├── mobile-game-server/    → FastAPI backend (Python)
└── docs/                  → All spec documents
```

---

## START COMMANDS

```bash
# Backend
cd mobile-game-server
redis-server &
uv run uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Frontend
cd mobile-game
flutter run

# Backend docs: http://localhost:8000/docs
# Backend health: http://localhost:8000/health
```

---

## 5 AI AGENTS AT A GLANCE

| Agent | File | When Called | Model | Fallback |
|-------|------|-------------|-------|---------|
| DungeonMasterAgent | agents/dungeon_master.py | Session start (once) | flash-thinking | FALLBACK_SESSION_PLAN |
| LevelGeneratorAgent | agents/level_generator.py | Per floor (once) | flash | FALLBACK_LEVELS[theme] |
| RivalAgent | agents/rival_agent.py | Per enemy per turn | flash | base_behavior_fallback() |
| NarrativeAgent | agents/narrative_agent.py | Key events | flash | NARRATIVE_FALLBACKS[event] |
| RefereeAgent | agents/referee_agent.py | Per player action | flash (edge cases only) | Pure Python rules |

---

## API ROUTES QUICK REF

```
POST /agent/dungeon-master     → SessionPlan
POST /agent/generate-level     → LevelSchema
POST /agent/npc-decision       → EnemyAction
POST /agent/validate-action    → ActionResult
POST /agent/narrative          → NarrativeResponse
GET  /traces/{session_id}      → TraceLog
GET  /players/{uid}/history    → PlayerHistory
POST /players/{uid}/session    → Save result
GET  /leaderboard              → Top 20
GET  /health                   → Status
```

---

## TILE VALUES

```
0 = WALL (black)         3 = LAVA (orange, damages)
1 = FLOOR (brown)        4 = TRAP (hidden, damages on step)
2 = unused               5 = unused (items in items[] array)
EXIT: floor tile at exit_position
ITEM: floor tile + entry in items[] array
```

---

## DAMAGE FORMULA

```python
damage = max(1, attacker_attack - defender_defense)
xp_for_kill = floor(enemy_max_hp / 5)
score = (floors_cleared × 100) + (remaining_hp × 2) + (enemies_killed × 10)
```

---

## CHARACTER CLASSES

| Class | HP | ATK | DEF | Special |
|-------|----|----|-----|---------|
| Warrior | 150 | 20 | 8 | Melee ×1.5 |
| Mage | 80 | 35 | 3 | Range 2 tiles |
| Ranger | 100 | 25 | 5 | Dash once |

---

## LEVEL SIZES BY DIFFICULTY

| Difficulty | Grid | Enemies | Items |
|-----------|------|---------|-------|
| 1-3 | 10×10 | 2-3 | ~2 |
| 4-6 | 12×12 | 3-5 | ~2 |
| 7-10 | 15×15 | 5-8 | ~1 |

---

## DIFFICULTY RULES (DM Agent)

```
loss_rate > 70%:  difficulty 1-4,  speed 0.8, items 1.5  → "struggling"
loss_rate 50-70%: difficulty 3-6,  speed 1.0, items 1.0  → "below average"
loss_rate 30-50%: difficulty 5-7,  speed 1.0, items 1.0  → "average"
loss_rate < 30%:  difficulty 7-10, speed 1.3, items 0.8  → "excelling"
```

---

## THEMES & ENEMIES

```
cursed_library:  shadow_mage | book_golem | librarian
volcanic_caves:  fire_elemental | rock_troll | lava_sprite
enchanted_forest: goblin | forest_witch | druid
```

---

## REDIS KEYS

```
session:{id}:dm_plan          TTL=3600  (SessionPlan)
session:{id}:player_tactics   TTL=3600  (PlayerTacticsProfile)
session:{id}:npc_memory:{eid} TTL=3600  (enemy memory)
level:{hash}                  TTL=86400 (LevelSchema)
player:{uid}:history          TTL=300   (PlayerHistory)
npc:{hash}                    TTL=30    (EnemyAction cache)
ratelimit:{uid}:agent_calls   TTL=60    (rate limit counter)
```

---

## FIREBASE COLLECTIONS

```
players/{uid}                     → Player profile
players/{uid}/stats/all_time      → Lifetime stats
players/{uid}/sessions/{id}       → Session records
sessions/{id}                     → Global session index
traces/{id}                       → Trace parent doc
traces/{id}/entries/{auto}        → Individual trace entries
levels/{hash}                     → Cached AI-generated levels
leaderboard/{uid}                 → Global rankings
```

---

## FLUTTER ROUTES

```
/auth             → AuthScreen
/menu             → MainMenuScreen
/character-select → CharacterSelectScreen
/game             → GameScreen
/result           → PostGameScreen
/traces/:id       → TraceViewerScreen
/leaderboard      → LeaderboardScreen
```

---

## RIVERPOD PROVIDERS

```dart
authProvider          → AsyncValue<User?>
playerProvider        → AsyncValue<PlayerModel>
sessionProvider       → StateNotifier<SessionModel>
gameStateProvider     → StateNotifier<GameState>
traceProvider         → StateNotifier<List<TraceEntry>>
```

---

## GAME STATE STATUS VALUES

```
"loading"       → AI generating session/level
"playing"       → Active gameplay (player's turn)
"enemy_turn"    → AI processing enemy moves
"animating"     → Playing combat animation
"transition"    → Between floors
"game_over_win" → Session won
"game_over_lose"→ Player died
```

---

## AGENT COLORS (for UI)

```dart
DungeonMasterAgent:  Color(0xFFD4AF37)  // Gold
LevelGeneratorAgent: Color(0xFF059669)  // Emerald
RivalAgent:          Color(0xFFEF4444)  // Crimson
NarrativeAgent:      Color(0xFF7C3AED)  // Violet
RefereeAgent:        Color(0xFF2563EB)  // Sapphire
```

---

## TRACE MUST-HAVES (judges check these)

```
✓ reasoning: specific numbers, not generic text
✓ tool_input: real data passed to tool
✓ tool_output: real result returned
✓ decision: concrete changes made (values before/after)
✓ 4 steps for DM agent, 4 for Level agent
✓ duration_ms logged for every step
✓ fallback_used: true when AI is bypassed
```

---

## LATENCY TARGETS

```
DungeonMaster:    < 3s  (8s max, then fallback)
Level Generator:  < 3s  (8s max, then fallback)
NPC Decision:     < 1s  (1.5s max, then base behavior)
Action Validate:  < 50ms (pure Python, no Gemini)
Narrative:        < 2s  (3s max, then hardcoded text)
```

---

## PRIORITY ORDER (build in this order)

```
1. FastAPI scaffold (mock routes)
2. Flutter scaffold (all screens, navigation)
3. Flame dungeon renderer (hardcoded level)
4. Player movement + basic combat (Flame)
5. BaseAgent + LevelGeneratorAgent
6. Connect Flutter ↔ Level API ↔ Flame
7. DungeonMasterAgent
8. AI Decision Panel widget
9. RivalAgent + RefereeAgent
10. Firebase save/load
11. NarrativeAgent + post-game screen
12. Trace viewer screen
13. Polish + demo prep
```

---

## DEMO SCRIPT (3 minutes)

```
0:00-0:30  Open app. Log in. Show player stats (10 losses).
0:30-1:00  Tap NEW RUN. Show "DM thinking...". 
           Cut to Antigravity showing agent trace in terminal.
           "Loss rate 80% → easy mode applied."
1:00-2:00  Play 1 floor. Show live AI Decision Panel updating.
           Enemy adapts: "Shadow Mage → ranged because player rushed."
2:00-2:30  Open Trace Viewer. Show all 7 decisions formatted beautifully.
           "The AI made 7 decisions before you took your first step."
2:30-3:00  Architecture slide: "5 agents, built in Antigravity, real-time traces."
           Close: "Remove the AI agents and the game stops working."
```

---

## CRITICAL RULES (never break these)

```
1. Never return 500 to Flutter — always fallback
2. Never block UI for AI — all calls async with loading state
3. Never remove a trace step — judges count them
4. Never skip schema validation — bad JSON = game crash
5. Never use image assets — colored shapes only (hackathon speed)
6. Never commit unreviewed Antigravity code
7. Always Redis-first for reads, Firestore for truth
8. Always log errors server-side even when returning fallback
```

---

## DOC FILE PURPOSES

| File | Purpose | Agent reads it |
|------|---------|---------------|
| PRD.md | What + why | All agents (intro) |
| ARCHITECTURE.md | How system works | ALL agents (mandatory) |
| GAMEPLAY_LOOP.md | Game rules/mechanics | Flutter + AI agents |
| AI_BEHAVIOR_SPECS.md | Agent inputs/outputs/rules | AI Systems agent |
| PROMPT_SPECS.md | Exact Gemini prompts | AI Systems agent |
| API_CONTRACTS.md | Route schemas | Backend + Flutter agents |
| DATABASE_SCHEMA.md | DB structure | Backend agent |
| JSON_SCHEMAS.md | Data structure definitions | ALL agents |
| UI_SPECS.md | Screen layouts + components | Flutter agent |
| TRACE_FORMAT.md | How to log reasoning | AI Systems agent |
| ANTIGRAVITY_PROMPTS.md | Copy-paste prompts | YOU (not agents) |
| QUICK_REF.md | This file | YOU (always open) |

---

*Keep this file open in a separate tab at all times.*
*When in doubt: check this file first, then the relevant spec doc.*
