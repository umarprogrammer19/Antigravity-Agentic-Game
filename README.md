# 🏰 DungeonMind

### An AI-Powered Roguelike Dungeon Crawler
**Google Antigravity Hackathon Submission — Mobile App Alchemy: Agentic Game Quest**

---

> *"Remove the AI agents and the game stops working. That's not AI as a feature — that's AI as the engine."*

---

## 🎮 What Is DungeonMind?

DungeonMind is a turn-based roguelike dungeon crawler where **five specialized Gemini AI agents serve as the living brain of the game** — running in real time during every session, every turn, and every decision.

This is not AI as a decoration. Every player action triggers at least one Gemini agent call. Every dungeon is generated fresh by AI. Every enemy decision is made by AI. Every story beat is written by AI. Every session is personalized by AI before you take your first step.

- **Struggling?** Your AI Dungeon Master quietly reduces difficulty, switches themes, and increases item drops — without telling you
- **Dominating?** Enemies get smarter after 3 turns by reading your pattern and switching tactics
- **Every run is unique** — procedurally generated floors, AI-adapted difficulty, AI-written narrative
- **Every AI decision is visible** — the live AI Decision Panel shows agent reasoning in real time

---

## 🤖 Five Agents. All Runtime. All Live.

These agents do not run during development. They run **during your gameplay session**, on every turn, reacting to your actions in real time.

| Agent | Runtime Role | Model | Triggered By |
|-------|-------------|-------|-------------|
| **DungeonMasterAgent** | Reads full player history, computes engagement level, personalizes session difficulty, theme, enemy speed, item drop rate | Gemini 3.1 Flash Lite | Player taps NEW RUN |
| **LevelGeneratorAgent** | Generates a unique dungeon floor as a validated JSON grid — enemies, items, layout, exit path | Gemini 3.1 Flash Lite | Each floor start |
| **RivalAgent** | Controls each enemy's turn. After 3 moves, reads player tactics and overrides base behavior to counter them | Gemini 3.1 Flash Lite | Every enemy turn |
| **NarrativeAgent** | Writes 1-2 sentence dark fantasy story text for floor clears, deaths, items, boss encounters | Gemini 3.1 Flash Lite | Key game events |
| **RefereeAgent** | Validates every player action, computes combat damage, grants XP rewards, enforces rules | Pure Python + Gemini (edge cases) | Every player action |

### Why This Matters
If you shut down the AI backend, the game shows a loading screen and never starts. The dungeon does not exist without LevelGeneratorAgent. The session plan does not exist without DungeonMasterAgent. Enemy turns do not resolve without RivalAgent. **The AI is not a feature. It is the game.**

---

## 🔄 The Agentic Gameplay Loop

```
Player taps NEW RUN
        ↓
DungeonMasterAgent reads player history
→ Computes loss_rate, engagement category, avg_floors_cleared
→ Sets: difficulty, theme, enemy_speed, item_drop_rate, boss_difficulty
→ Writes: personalized narrative_intro
        ↓
LevelGeneratorAgent generates Floor 1
→ Creates 10×10 to 15×15 validated grid
→ Places enemies, items, exit — checks path exists
→ Returns: LevelSchema JSON
        ↓
Player enters dungeon
        ↓
[Every Player Turn]
Player moves/attacks
        ↓
RefereeAgent validates action
→ Checks rules, computes damage, grants XP, detects floor clear
        ↓
[Every Enemy Turn — per enemy]
RivalAgent reads player_tactics_profile from Redis
→ After turn 3: overrides base behavior based on observed patterns
→ Decides: move / attack / ability / wait
        ↓
[Key Events]
NarrativeAgent generates atmospheric text
→ Specific to theme, class, floor, event type
        ↓
Floor 5 cleared → Session Win
Player HP = 0  → Session Loss + DungeonMaster feedback + difficulty adjustment
```

---

## 📊 Engagement Tracking & Adaptive Difficulty

The DungeonMasterAgent is the engagement tracking system. Before every session it computes:

```python
loss_rate = losses / max(1, total_sessions)

# Engagement categories:
loss_rate > 70%  → "struggling"   → difficulty 1-4,  speed 0.8x, items 1.5x
loss_rate 50-70% → "below avg"   → difficulty 3-6,  speed 1.0x, items 1.0x
loss_rate 30-50% → "average"     → difficulty 5-7,  speed 1.0x, items 1.0x
loss_rate < 30%  → "excelling"   → difficulty 7-10, speed 1.3x, items 0.8x
```

This runs on every session start — the game adapts to the player's engagement history, not a static difficulty slider. The player never sees a "difficulty" setting. They just feel the game getting easier or harder.

---

## ⚔️ Baseline Comparison

DungeonMind includes a non-agentic baseline mode for evaluation purposes.

| Capability | Agentic Mode (AI On) | Baseline Mode (AI Off) |
|-----------|---------------------|----------------------|
| Session planning | DungeonMasterAgent reads history, computes difficulty | Hardcoded: difficulty=3, enchanted_forest |
| Level generation | LevelGeneratorAgent creates unique grid | Pre-built fallback levels from `fallbacks/fallback_levels.py` |
| Enemy AI | RivalAgent adapts to player tactics after 3 turns | Base behavior only: rush_melee, tank_melee, etc. |
| Narrative | NarrativeAgent writes theme-specific story | Static hardcoded strings from `NARRATIVE_FALLBACKS` |
| Action validation | RefereeAgent with Gemini edge case handling | Pure Python rule validation only |
| Difficulty adaptation | Recomputed every session based on history | Never changes |

The fallback system already exists in the codebase (`fallback_used: true` in traces). Baseline mode is what happens when the AI backend is unavailable — the game is playable but static, repetitive, and unadaptive.

To toggle baseline mode: set `BASELINE_MODE=true` in `.env`. All agent calls return their hardcoded fallback immediately.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Flutter Mobile App                     │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───────────┐   │
│  │GameScreen│ │AI Panel  │ │TraceView │ │PostGame   │   │
│  │(Flame)   │ │(Live)    │ │(Judges)  │ │(Feedback) │   │
│  └────┬─────┘ └──────────┘ └──────────┘ └───────────┘   │
└───────┼─────────────────────────────────────────────────┘
        │ HTTP REST (async, timeout + fallback)
        ▼
┌─────────────────────────────────────────────────────────┐
│              FastAPI Backend (Python)                   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │              5 Runtime AI Agents                │    │
│  │                                                 │    │
│  │  DungeonMaster → LevelGenerator → Rival         │    │
│  │       ↕               ↕            ↕            │    │
│  │  Narrative  ←→  Referee  ←→  BaseAgent          │    │
│  └────────────────────┬────────────────────────────┘    │
│                       │                                 │
│  ┌──────────────┐     │     ┌──────────────────────┐    │
│  │ Redis Cache  │◄────┤────►│ Gemini 3.1 Flash Lite|    │   
│  │ (agent mem)  │     │     │   (runtime AI calls) │    │
│  └──────────────┘     │     └──────────────────────┘    │
│                       │                                 │
│  ┌────────────────────▼─────────────────────────────┐   │
│  │              Firebase                            │   │
│  │  Firestore (sessions, traces, leaderboard)       │   │
│  │  Realtime DB (live AI status → AI panel)         │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter 3.x + Flame game engine + Riverpod |
| Backend | Python FastAPI + uvicorn |
| Runtime AI | Google Gemini 3.1 Flash Lite |
| Development Environment | Google Antigravity |
| Database | Firebase Firestore + Realtime Database |
| Agent Memory | Redis (tactics profile, session cache, rate limiting) |
| Navigation | GoRouter |
| State Management | Riverpod |

---

## 🔧 How Google Antigravity Was Used

### As the Development Environment
The entire project was built inside Google Antigravity using specialized agents:

- **Backend Architect Agent** — Scaffolded all FastAPI routes, Pydantic models, Firebase service
- **Flutter Architect Agent** — Built all screens, Flame integration, navigation, state management
- **AI Systems Engineer Agent** — Implemented all 5 game agents, prompts, trace logging
- **Debugger Agent** — Resolved integration issues, edge cases, validation errors

All Antigravity session artifacts are saved in `docs/ANTIGRAVITY_TRACES/`.

### As the Runtime AI Foundation
Google's Gemini model (accessed via Antigravity's AI infrastructure) powers all 5 agents at runtime. Every session, every turn, every decision routes through Gemini. The agents are not wrappers — they maintain state in Redis, share player tactics profiles across turns, retry on validation failure, and fall back gracefully so the game never crashes.

---

## 📁 Project Structure

```
antigravity-game/
├── mobile-game/                    # Flutter application
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/
│   │   │   ├── router.dart
│   │   │   └── theme.dart
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── menu/
│   │   │   ├── character_select/
│   │   │   ├── game/               # Flame engine + HUD + AI panel
│   │   │   ├── traces/             # Trace viewer (judge evaluation)
│   │   │   └── leaderboard/
│   │   ├── models/
│   │   ├── providers/              # Riverpod state
│   │   └── services/
│   └── pubspec.yaml
│
├── mobile-game-server/             # Python backend
│   ├── main.py
│   ├── agents/
│   │   ├── base_agent.py           # Tracing, Gemini client, fallback logic
│   │   ├── dungeon_master.py       # Session planner + engagement tracker
│   │   ├── level_generator.py      # Procedural dungeon architect
│   │   ├── rival_agent.py          # Adaptive enemy brain
│   │   ├── narrative_agent.py      # Dark fantasy storyteller
│   │   └── referee_agent.py        # Rule enforcer + reward granter
│   ├── routers/
│   ├── models/
│   ├── services/
│   └── fallbacks/                  # Baseline mode + safety nets
│
└── docs/
    ├── PRD.md
    ├── ARCHITECTURE.md
    ├── GAMEPLAY_LOOP.md
    ├── AI_BEHAVIOR_SPECS.md
    ├── PROMPT_SPECS.md
    ├── API_CONTRACTS.md
    ├── DATABASE_SCHEMA.md
    ├── JSON_SCHEMAS.md
    ├── UI_SPECS.md
    ├── TRACE_FORMAT.md
    └── ANTIGRAVITY_TRACES/         # Exported build session artifacts
```

---

## 🚀 Setup & Running

### Prerequisites
```
Flutter 3.x
Python 3.12+
uv package manager
Redis
Firebase project
Gemini API key (Google AI Studio)
```

### Backend Setup
```bash
cd mobile-game-server
uv sync

# Create .env
cp .env.example .env
# Fill in: GEMINI_API_KEY, FIREBASE_CREDENTIALS_PATH, REDIS_URL
# Optional: BASELINE_MODE=true  (disables AI, uses fallbacks only)

# Add Firebase service account JSON
# Place serviceAccountKey.json in mobile-game-server/

redis-server
uv run uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Verify: http://localhost:8000/docs
# Health: http://localhost:8000/health
```

### Flutter Setup
```bash
cd mobile-game
flutter pub get
# Run: flutterfire configure OR add google-services.json manually
# Set backend URL in lib/config/env.dart

flutter run
```

### Environment Variables
```env
GEMINI_API_KEY=your_key_here
FIREBASE_CREDENTIALS_PATH=serviceAccountKey.json
FIREBASE_DATABASE_URL=https://your-project-default-rtdb.firebaseio.com
REDIS_URL=redis://localhost:6379
APP_ENV=development
LOG_LEVEL=INFO
BASELINE_MODE=false
```

---

## 🎯 How to Play

1. **Sign In** — Google or anonymous
2. **Choose Class** — Warrior (melee tank), Mage (ranged glass cannon), Ranger (balanced)
3. **Watch the DM Think** — AI analyzes your history and personalizes your run
4. **Explore** — D-pad to move. Move into enemies to attack.
5. **Watch the AI Panel** — See every agent decision happening in real time
6. **Reach the Exit** — Green tile clears the floor
7. **Survive 5 Floors** — Floor 5 has a boss. Clear it to win.
8. **Review AI Traces** — After the run, see every decision the agents made

---

## 🔍 Live AI Decision Panel — The Key Demo Feature

During gameplay, a draggable panel at the bottom of the screen shows every agent decision as it happens:

```
🧠 Rival: Shadow Mage switched to ranged — detected melee preference (3 turns)
🧠 DM: loss_rate = 0.80 → difficulty 3, enchanted_forest, items ×1.5
🧠 Level: 10×10 grid generated — path valid — difficulty score 3.2/10
🧠 Referee: move validated — floor tile confirmed — no enemy collision
🧠 Narrative: floor_cleared event — "The shadows retreat. Floor 2 waits."
```

Collapsed: 1-line summary of last agent decision.
Expanded (drag up): Full reasoning log with tool inputs/outputs, timestamps, token counts.

---

## 📈 Agent Trace Example (Real Output)

```
SESSION START — warrior, 10 sessions, 2 wins, 8 losses

[DungeonMasterAgent — Step 1 — 10:32:01]
REASONING: "8 losses, 2 wins. loss_rate = 8/10 = 0.80."
TOOL: compute_player_stats
DECISION: "Struggling category. Applying easy mode parameters."

[DungeonMasterAgent — Step 2 — 10:32:02]
REASONING: "loss_rate 0.80 exceeds 70% threshold → difficulty 1-4.
             avg_floors_cleared=2.3 → difficulty set to 3.
             enemy_speed=0.8x, item_drop=1.5x."
TOOL: set_difficulty_params
DECISION: "difficulty=3, enchanted_forest, items×1.5"

[DungeonMasterAgent — Step 3 — 10:32:02]
REASONING: "3 consecutive losses. Easiest theme selected."
TOOL: select_theme
DECISION: "Theme: enchanted_forest"

[LevelGeneratorAgent — Step 1 — 10:32:04]
REASONING: "Floor 1, difficulty 3 → 10×10 grid, 3 enemies, 2 items."
TOOL: generate_grid → validate_path
DECISION: "Level valid. Path confirmed. difficulty_score=3.2"

[Total: 7 AI decisions before player takes a single step]
```

---

## 🏆 Evaluation Criteria Alignment

| Criterion | Weight | Our Implementation |
|-----------|--------|--------------------|
| **Antigravity Integration** | 25% | 5 Gemini agents run at runtime on every turn. Built entirely in Antigravity. Exported traces in docs/. |
| **Gameplay Engagement** | 25% | DungeonMaster tracks engagement per session. Difficulty adapts invisibly. NPC learning after turn 3. Live AI panel keeps players watching. |
| **Agentic Innovation** | 20% | Cross-agent Redis memory sharing. Player tactics profile updated per turn. Agents retry, fall back, and log everything. |
| **Technical Polish** | 15% | <1s NPC decisions. Never returns 500. All async with loading states. Pydantic schema validation on all AI outputs. |
| **Creativity** | 10% | AI as Dungeon Master framing. Real-time reasoning visibility. Dark fantasy narrative generated per event. |
| **Baseline Comparison** | 5% | `BASELINE_MODE=true` disables all agents, uses fallback_levels and hardcoded behavior. Measurable difference in adaptivity. |

---

## 📝 Assumptions & Limitations

- All game art uses colored rectangles — chosen intentionally for hackathon speed
- Multiplayer not implemented — single-player only
- NPC tactic learning requires 3+ turns of data — first 3 turns use base behavior
- Gemini latency: 1-3s for level generation — shown as "dungeon shifting" animation
- Redis required locally — cloud Redis for production
- Demo uses pre-seeded account (10 losses, 0 wins) for optimal DM adaptation demo

---

*DungeonMind — Where the AI thinks so the dungeon breathes.*
*Built with Google Antigravity | Google Antigravity Hackathon 2026*
