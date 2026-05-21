# DungeonMind — Quick Reference Card
### Everything in one place. Keep this open always.
---

## THE GAME IN 3 LINES
Turn-based roguelike dungeon crawler.
5 Gemini AI agents run at runtime: they generate levels, control enemies, tell stories, validate actions, and adapt to you every session.
Every decision they make is shown live on screen during gameplay.

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
# Health check: http://localhost:8000/health

# Baseline mode (disables all AI — hardcoded fallbacks only):
# Set BASELINE_MODE=true in .env then restart backend
```

---

## 5 RUNTIME AI AGENTS

| Agent | File | Called When | Model | Fallback |
|-------|------|-------------|-------|---------|
| DungeonMasterAgent | agents/dungeon_master.py | Session start (once) | gemini-3.1-flash-lite | FALLBACK_SESSION_PLAN |
| LevelGeneratorAgent | agents/level_generator.py | Per floor (once) | gemini-3.1-flash-lite | FALLBACK_LEVELS[theme] |
| RivalAgent | agents/rival_agent.py | Per enemy per turn | gemini-3.1-flash-lite | base_behavior_fallback() |
| NarrativeAgent | agents/narrative_agent.py | Key game events | gemini-3.1-flash-lite | NARRATIVE_FALLBACKS[event] |
| RefereeAgent | agents/referee_agent.py | Per player action | gemini-3.1-flash-lite (edge only) | Pure Python rules |

**All 5 agents run during active gameplay. They are the runtime orchestrators, not development tools.**

---

## API ROUTES

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
0 = WALL (black)         3 = LAVA (orange, 5 dmg/step)
1 = FLOOR (brown)        4 = TRAP (hidden, 15 dmg on step)
2 = unused               EXIT: floor tile at exit_position
                         ITEM: floor tile + entry in items[] array
```

---

## DAMAGE FORMULA

```python
damage = max(1, attacker_attack - defender_defense)
xp_for_kill = floor(enemy_max_hp / 5)
score = (floors_cleared × 100) + (remaining_hp × 2) + (enemies_killed × 10)
speed_bonus = +200 if session_turns < 50
class_bonus = score × 1.5 if class == "mage"
```

---

## CHARACTER CLASSES

| Class | HP | ATK | DEF | Special |
|-------|----|-----|-----|---------|
| Warrior | 150 | 20 | 8 | Melee ×1.5 |
| Mage | 80 | 35 | 3 | Range 2 tiles |
| Ranger | 100 | 25 | 5 | Dash once per floor |

---

## LEVEL SIZES BY DIFFICULTY

| Difficulty | Grid | Enemies | Items (base) |
|-----------|------|---------|-------------|
| 1-3 | 10×10 | 2-3 | ~2 |
| 4-6 | 12×12 | 3-5 | ~2 |
| 7-10 | 15×15 | 5-8 | ~1 |

---

## ENGAGEMENT TRACKING & DIFFICULTY (DM Agent)

```
loss_rate = losses / max(1, total_sessions)

loss_rate > 70%:  difficulty 1-4,  speed 0.8x, items 1.5x → "struggling"
loss_rate 50-70%: difficulty 3-6,  speed 1.0x, items 1.0x → "below average"
loss_rate 30-50%: difficulty 5-7,  speed 1.0x, items 1.0x → "average"
loss_rate < 30%:  difficulty 7-10, speed 1.3x, items 0.8x → "excelling"
```

---

## BASELINE MODE (for demo comparison)

```bash
# In mobile-game-server/.env:
BASELINE_MODE=true

# Effect: all agent calls return hardcoded fallbacks instantly
# No Gemini calls. No adaptation. No tactic learning.
# Difficulty never changes between sessions.
# Use this to show judges what the game is like WITHOUT AI.
```

---

## THEMES & ENEMIES

```
cursed_library:   shadow_mage | book_golem | librarian
volcanic_caves:   fire_elemental | rock_troll | lava_sprite
enchanted_forest: goblin | forest_witch | druid
```

---

## REDIS KEYS

```
session:{id}:dm_plan          TTL=3600  (SessionPlan — shared with LevelGenerator)
session:{id}:player_tactics   TTL=3600  (PlayerTacticsProfile — updated by RivalAgent each turn)
session:{id}:npc_memory:{eid} TTL=3600  (per-enemy memory)
level:{hash}                  TTL=86400 (cached generated level)
player:{uid}:history          TTL=300   (cached Firestore read)
npc:{hash}                    TTL=30    (cached enemy action)
ratelimit:{uid}:agent_calls   TTL=60    (60 calls/min enforced)
```

---

## FIREBASE COLLECTIONS

```
players/{uid}                     → Player profile
players/{uid}/stats/all_time      → Engagement metrics (loss_rate source)
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
"loading"        → AI generating session/level
"playing"        → Active gameplay (player's turn)
"enemy_turn"     → AI processing enemy moves
"animating"      → Playing combat animation
"transition"     → Between floors
"game_over_win"  → Session won (floor 5 cleared)
"game_over_lose" → Player died
```

---

## AGENT COLORS (UI)

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
✓ reasoning: specific numbers (loss_rate=0.80, not "player is struggling")
✓ tool_input: real data passed in
✓ tool_output: real result returned
✓ decision: concrete action taken (values before/after)
✓ 4 steps minimum for DM and Level agents
✓ duration_ms logged for every step
✓ fallback_used: true when AI is bypassed (shows robustness)
✓ tokens_used: logged for every Gemini call
```

---

## LATENCY TARGETS

```
DungeonMaster:    < 3s  (8s max → FALLBACK_SESSION_PLAN)
Level Generator:  < 3s  (8s max → FALLBACK_LEVELS[theme])
NPC Decision:     < 1s  (1.5s max → base_behavior_fallback())
Action Validate:  < 50ms (pure Python, no Gemini)
Narrative:        < 2s  (3s max → NARRATIVE_FALLBACKS[event])
```

---

## EVALUATION CRITERIA (correct weights)

```
Antigravity Integration:  25%  ← runtime agents, Antigravity build traces
Gameplay Engagement:      25%  ← DM engagement tracking, NPC tactic learning, AI panel
Agentic Innovation:       20%  ← cross-agent Redis memory, retry logic, live adaptation
Technical Polish:         15%  ← latency, fallbacks, Pydantic validation, never 500
Creativity:               10%  ← DM framing, real-time reasoning visibility, narrative
Baseline Comparison:       5%  ← BASELINE_MODE=true vs agentic mode demo
```

---

## DEMO SCRIPT (3 minutes)

```
0:00-0:30  Open app. Log in as demo account (10 losses, 0 wins).
           Show player stats on menu screen.

0:30-1:00  Tap NEW RUN. "DM thinking..." loading state.
           AI panel shows: "loss_rate = 10/10 = 1.00 → easy mode"
           Optional: cut to Antigravity terminal showing trace.

1:00-2:00  Play floor 1 live. AI Decision Panel updating every turn:
           "Rival: Goblin → ranged (detected melee preference, 3 turns)"
           "Referee: move validated — 28ms"

2:00-2:30  Die or clear. Open Trace Viewer.
           "7 AI decisions before you took your first step."
           Show token counts, reasoning, tool inputs.

2:30-3:00  Toggle BASELINE_MODE=true briefly → show static dungeon.
           Toggle back. "Without AI: static. With AI: alive."
           Close: "Remove the agents and the game stops working."
```

---

## CRITICAL RULES (never break these)

```
1. Never return 500 to Flutter — always fallback + fallback_used:true
2. Never block UI for AI — all calls async with loading state
3. Never remove a trace step — judges count them
4. Never skip schema validation — bad JSON = game crash
5. Never use image assets — colored shapes only
6. Always Redis-first for reads, Firestore for truth
7. Always log errors server-side even when returning fallback
8. Always describe agents as runtime orchestrators, not dev tools
```

---

## DOC FILE PURPOSES

| File | Purpose | Who reads it |
|------|---------|-------------|
| PRD.md | What + why + evaluation alignment | All agents (mandatory first read) |
| ARCHITECTURE.md | System design + data flow | All agents (mandatory) |
| GAMEPLAY_LOOP.md | Game rules and mechanics | Flutter + AI agents |
| AI_BEHAVIOR_SPECS.md | Agent inputs/outputs/prompts/rules | AI Systems agent |
| PROMPT_SPECS.md | Exact Gemini prompt templates | AI Systems agent |
| API_CONTRACTS.md | Route request/response schemas | Backend + Flutter agents |
| DATABASE_SCHEMA.md | Firestore + Redis structure | Backend agent |
| JSON_SCHEMAS.md | All data model definitions | All agents |
| UI_SPECS.md | Screen layouts + component specs | Flutter agent |
| TRACE_FORMAT.md | How to log reasoning steps | AI Systems agent |
| QUICK_REF.md | This file | You (always open) |

---

*Keep this file open at all times.*
*When in doubt: check this file first, then the relevant spec doc.*
