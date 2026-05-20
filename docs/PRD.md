# DungeonMind — Product Requirements Document (PRD)
### Version 2.1 | Google Antigravity Hackathon — Mobile App Alchemy: Agentic Game Quest
### Reference for: ALL agents — read this before ANY task
---

## 1. PRODUCT OVERVIEW

### Product Name
**DungeonMind** — An AI-Powered Roguelike Dungeon Crawler

### One-Line Pitch
A mobile dungeon crawler where five Gemini AI agents run at runtime as your Dungeon Master, enemy brain, storyteller, rule enforcer, and tactical coach — making every decision visible, every run personalized, and every session adapted to your engagement history.

### Core Problem Being Solved
Most roguelike games use static procedural generation. Difficulty never truly adapts to the individual player. A beginner and an expert play through the same statistical distribution. DungeonMind uses five AI agents that operate as the game engine itself:

1. **Observe** — Every session, agents read player history, engagement metrics, and in-game tactics
2. **Infer** — Agents compute skill level, preferred strategy, engagement category, and stress points
3. **Decide** — Agents set difficulty, generate unique dungeons, control enemies, write narrative
4. **Execute** — Decisions appear as real gameplay: harder enemies, different layouts, adapted story
5. **Evaluate** — Outcomes are stored and fed back into the next session's agent context

This is the full agentic loop: observe → infer → decide → execute → evaluate.

### Why This Wins the Hackathon
- **Agentic gameplay loop:** The game cannot run without the AI agents. Remove them and you get a loading screen.
- **Runtime orchestration:** All 5 agents fire during active gameplay — not as preprocessing, as the game engine.
- **Visible AI reasoning:** Judges can watch every agent decision stream to the screen in real time.
- **Engagement tracking:** DungeonMaster computes engagement per session and adapts invisibly.
- **Baseline comparison included:** Toggle `BASELINE_MODE=true` to see non-agentic gameplay for direct comparison.
- **Quotable demo moment:** "The AI made 7 decisions before you took your first step."

---

## 2. TARGET USERS

### Primary User: Hackathon Judges
They want to see:
- Google Antigravity agents running at runtime, not just during development
- AI making non-trivial decisions with traceable reasoning (specific numbers, formulas, conclusions)
- Adaptive difficulty that responds to real player engagement data
- A working, playable game — not a mocked demo
- Baseline comparison demonstrating measurable AI impact

**What we give them:**
- Live AI Decision Panel streaming agent reasoning during gameplay
- Trace Viewer screen with full per-session agent decision logs
- `BASELINE_MODE=true` flag that removes AI and shows the difference
- Pre-seeded demo account (10 losses, 0 wins) that reliably triggers easy-mode adaptation

### Secondary User: Mobile Gamers
They want a game that knows them, challenges them appropriately, and feels alive.

**What we give them:**
- DungeonMaster that silently adapts between sessions
- Enemies that learn their tactics mid-game
- Narrative that references their class, theme, and events
- Consistent difficulty progression that responds to their actual skill

---

## 3. CORE FEATURES

### F-01: Runtime AI Dungeon Master (Engagement Tracker + Session Planner)
**What it does at runtime:** Before every session, reads the player's complete history from Firestore. Computes `loss_rate`, `avg_floors_cleared`, `favorite_death_cause`, and `engagement_category`. Generates a fully personalized session plan: difficulty level, theme, enemy speed multiplier, item drop rate, boss difficulty, recommended strategy, and a narrative intro written for this specific player.

**Why this is agentic:** The session plan is not a lookup table. Gemini reasons over the player's exact history and writes a unique plan. Every player gets a different starting configuration based on their engagement data.

**Spec:** `agents/dungeon_master.py` | `docs/AI_BEHAVIOR_SPECS.md — Agent 1`

### F-02: Runtime Procedural Level Generation
**What it does at runtime:** For each floor, generates a complete dungeon layout as a validated JSON grid. Enemy positions, item placements, exit location, and corridor structure are all AI decisions. The level is validated for playability (path from start to exit confirmed by BFS) before being sent to the client.

**Why this is agentic:** No two floors are identical. The AI adapts grid size, enemy count, and item density to the session's difficulty parameters set by the DungeonMaster.

**Spec:** `agents/level_generator.py` | `docs/AI_BEHAVIOR_SPECS.md — Agent 2`

### F-03: Runtime Adaptive Enemy AI (Tactic Learning)
**What it does at runtime:** Controls each enemy's turn every round. After 3 turns of observation, reads the `player_tactics_profile` from Redis (dominant direction, melee/ranged preference, retreat behavior, corner preference) and overrides the enemy's base behavior to counter the player's pattern.

**Why this is agentic:** The AI observes, learns, and adapts mid-game. A player who always rushes melee will find enemies switching to ranged. A player who retreats will find enemies cutting off escape routes.

**Spec:** `agents/rival_agent.py` | `docs/AI_BEHAVIOR_SPECS.md — Agent 3`

### F-04: Live AI Decision Panel (Most Important UI Feature for Judges)
**What it shows:** Every agent decision streamed to the screen in real time during gameplay. Collapsed: 1-line summary of last decision. Expanded: full reasoning chain with tool inputs/outputs, timestamps, token counts, and duration.

**Why judges care:** This makes the agentic system visible. Judges don't have to trust that AI is running — they can watch it think.

**Spec:** `docs/UI_SPECS.md — Screen 4`

### F-05: Runtime Atmospheric Narrative
**What it does at runtime:** Generates 1-2 sentence dark fantasy story text for session start, floor clears, item finds, boss encounters, and player deaths. Text is specific to the current theme, player class, floor number, and event context.

**Why this is agentic:** The narrative is not drawn from a pool of pre-written lines. Every event description is generated fresh by Gemini in response to the specific game state.

**Spec:** `agents/narrative_agent.py` | `docs/AI_BEHAVIOR_SPECS.md — Agent 4`

### F-06: Runtime Rule Enforcement + Reward Granting
**What it does at runtime:** Validates every player action. Standard moves: pure Python under 50ms. Edge cases (simultaneous collisions, special ability interactions, ambiguous situations): Gemini call. Computes and grants XP rewards based on enemy difficulty. Never crashes, never softlocks.

**Why this is agentic:** The agent decides the outcome of ambiguous situations that hardcoded rules cannot handle. It also determines XP rewards contextually.

**Spec:** `agents/referee_agent.py` | `docs/AI_BEHAVIOR_SPECS.md — Agent 5`

### F-07: Session Trace Viewer (Judge Evaluation Screen)
**What it shows:** After each run, a complete log of every AI decision: agent name, step number, reasoning text, tool called, tool input, tool output, decision made, model used, tokens consumed, duration in ms, and whether a fallback was used.

**Why judges care:** Full auditability of every AI decision in the session. Nothing is hidden.

**Spec:** `docs/UI_SPECS.md — Screen 7`

### F-08: Adaptive Post-Game Feedback
After death, the DungeonMaster's reasoning is displayed: "You died because X. Next time try Y. Your next session has been adjusted." This closes the agentic loop — the player sees the AI's evaluation of their session.

### F-09: Baseline Comparison Mode
**What it is:** `BASELINE_MODE=true` in `.env` disables all Gemini calls. All agents return their hardcoded fallbacks immediately. Level generation uses `fallback_levels.py`. Enemy AI uses base behavior only. Narrative uses `NARRATIVE_FALLBACKS`. Difficulty never changes between sessions.

**Why it matters:** Demonstrates measurable AI impact. In baseline mode, the dungeon is static and repetitive. In agentic mode, it adapts and responds.

---

## 4. AGENTIC SYSTEM DESIGN

### The Observe → Infer → Decide → Execute → Evaluate Loop

```
[OBSERVE]
DungeonMasterAgent reads: total_sessions, wins, losses, avg_floors_cleared,
                           favorite_death_cause, last_5_sessions, wins_by_theme

[INFER]
loss_rate = losses / max(1, total_sessions)
engagement_category: struggling | below_average | average | excelling

[DECIDE]
difficulty_level, enemy_speed_multiplier, item_drop_rate, theme, boss_difficulty
→ LevelGeneratorAgent receives these parameters
→ RivalAgent receives player_class and difficulty context

[EXECUTE]
Per-turn: RefereeAgent validates → RivalAgent controls enemies → NarrativeAgent writes
Player experience: dungeon feels harder/easier/different without any explicit difficulty label

[EVALUATE]
Session result saved to Firestore
Next session: DungeonMaster reads updated history
Loop continues
```

### Cross-Agent Memory (Redis)
Agents share state through Redis, not just through API calls:

```
session:{id}:dm_plan          → LevelGenerator reads difficulty params
session:{id}:player_tactics   → RivalAgent reads and writes tactics profile per turn
session:{id}:npc_memory:{eid} → Per-enemy observation state
level:{hash}                  → Cached generated levels (24h TTL)
player:{uid}:history          → Cached Firestore read (5min TTL)
```

### Engagement Tracking Metrics

| Metric | Computed By | Used By |
|--------|-------------|---------|
| loss_rate | DungeonMasterAgent | Difficulty calibration |
| avg_floors_cleared | DungeonMasterAgent | Difficulty fine-tuning |
| engagement_category | DungeonMasterAgent | Theme selection, item drop rate |
| favorite_death_cause | DungeonMasterAgent | Recommended strategy generation |
| dominant_direction | RivalAgent | Enemy tactic override |
| prefers_melee / prefers_ranged | RivalAgent | Enemy behavior switching |
| retreats_when_low_hp | RivalAgent | Enemy positioning |
| turns_observed | RivalAgent | Determines when adaptation activates |

---

## 5. GAME DESIGN

### Character Classes

| Class | HP | ATK | DEF | Playstyle |
|-------|----|-----|-----|-----------|
| Warrior | 150 | 20 | 8 | Melee +50%. Best for beginners. |
| Mage | 80 | 35 | 3 | Range 2 tiles. High damage, fragile. |
| Ranger | 100 | 25 | 5 | Balanced. Dash once per floor. |

### Dungeon Themes

| Theme | Enemies | Relative Difficulty |
|-------|---------|-------------------|
| Enchanted Forest | Goblin, Forest Witch, Druid | Easiest |
| Cursed Library | Shadow Mage, Book Golem, Librarian | Medium |
| Volcanic Caves | Fire Elemental, Rock Troll, Lava Sprite | Hardest |

### Win Condition
Survive all 5 floors. Floor 5 = boss floor.

### Loss Condition
Player HP reaches 0.

### Score Formula
```
Score = (floors_cleared × 100) + (remaining_hp × 2) + (enemies_killed × 10)
Speed bonus: if session_turns < 50 → +200
Class bonus: Mage × 1.5 (harder class)
```

---

## 6. TECHNICAL REQUIREMENTS

### Performance Targets

| Operation | Target | Maximum | On Timeout |
|-----------|--------|---------|-----------|
| DungeonMaster (session start) | < 3s | 8s | FALLBACK_SESSION_PLAN |
| Level generation | < 3s | 8s | FALLBACK_LEVELS[theme] |
| NPC decision (per enemy) | < 1s | 1.5s | base_behavior_fallback() |
| Action validation (standard) | < 50ms | 200ms | Pure Python always |
| Narrative | < 2s | 3s | NARRATIVE_FALLBACKS[event] |

### Reliability Rules
- Backend NEVER returns 500 — all failures return 200 + `fallback_used: true`
- All async Flutter calls have timeout + loading state + error state
- Every agent has a hardcoded fallback — game is playable without AI (baseline mode)
- `fallback_used: true` in traces proves robustness, not failure

### AI API Rules
- All Gemini calls: `response_mime_type="application/json"` + `response_schema`
- All responses validated with Pydantic before use
- Retry once on validation failure, then fallback
- Rate limit: 60 agent calls/player/minute (Redis enforced)

---

## 7. USER FLOWS

### New Player First Run
```
Open app → Auth → Character Select → Choose Warrior
→ DungeonMasterAgent: 0 sessions → difficulty 3, enchanted_forest
→ Play floor 1 → clear → floor 2 → die on floor 3
→ Death screen → AI feedback: "You died because X. Try Y."
→ Menu: "1 session, 0 wins"
```

### Returning Player (10 Losses)
```
Open app → Menu: 10 losses shown
→ NEW RUN → DungeonMasterAgent: loss_rate=1.0 → difficulty 2, enchanted_forest
→ AI panel: "DM: loss_rate 100% → easy mode applied"
→ Player clears 3 floors → RivalAgent: "Detected ranged preference → switching to melee rush"
→ Win session → PostGame: "Next run: difficulty adjusted upward"
```

### Judge Demo (3 Minutes)
```
0:00-0:30  Log in as pre-seeded demo account (10 losses)
           Menu shows: 10 sessions, 0 wins, avg_floors=2.0

0:30-1:00  Tap NEW RUN → "DM thinking..." loading state
           AI panel shows: "loss_rate = 10/10 = 1.00 → difficulty 2 applied"
           (Optional: show Antigravity terminal with full agent trace)

1:00-2:00  Play floor 1 live
           AI panel updating every turn:
           "Rival: Goblin switched to ranged — detected melee preference (3 turns)"
           "Referee: move validated — 32ms"
           "Narrative: floor hook written — enchanted_forest theme"

2:00-2:30  Open Trace Viewer after floor 1
           Show all 7 pre-game decisions formatted beautifully
           "7 AI decisions before you took your first step"

2:30-3:00  Toggle BASELINE_MODE briefly → show static dungeon, no adaptation
           Toggle back → "This is what AI removes when you take it out"
           Close: "Remove the agents and the game stops working."
```

---

## 8. NON-REQUIREMENTS (explicitly out of scope)

```
✗ Multiplayer          ✗ Image assets (colored shapes only)
✗ Sound / music        ✗ In-app purchases
✗ Offline mode         ✗ Tablet optimization
✗ Web version          ✗ More than 5 floors
✗ More than 3 themes or 3 classes
```

---

## 9. FEATURE PRIORITY

### P0 — Must Have (game breaks without)
- Firebase auth, Flame grid, player movement, combat
- DungeonMasterAgent, LevelGeneratorAgent, RefereeAgent
- AI Decision Panel, session save, post-game screen, trace logging

### P1 — Should Have (score suffers without)
- RivalAgent (tactic learning), NarrativeAgent, Trace Viewer, Leaderboard
- Baseline mode toggle, engagement tracking metrics in traces

### P2 — Nice to Have (polish)
- Combat animations, damage numbers, transition animations

### P3 — Cut if needed
- Sound, achievements, inventory screen

---

## 10. EVALUATION CRITERIA ALIGNMENT

| Criterion | Weight | Implementation | Evidence |
|-----------|--------|---------------|---------|
| **Antigravity Integration** | 25% | 5 runtime agents, all calling Gemini during gameplay. Full project built in Antigravity. | Trace logs, ANTIGRAVITY_TRACES/ exports, live AI panel |
| **Gameplay Engagement** | 25% | DungeonMaster computes engagement_category per session. RivalAgent adapts per turn. Difficulty invisible to player. | Session history, trace reasoning fields, demo with 10-loss account |
| **Agentic Innovation** | 20% | Cross-agent Redis memory. Player tactics profile updated per enemy turn. Retry → fallback → log chain. | Trace logs, redis_service.py, rival_agent.py |
| **Technical Polish** | 15% | <1s NPC decisions. Never 500. Pydantic validation on all AI outputs. Async with loading states. | API response times in traces, fallback_used flags |
| **Creativity** | 10% | "AI as Dungeon Master" — five specialized agents each with a game role. Real-time reasoning panel. | Live demo, AI panel UI, narrative variety |
| **Baseline Comparison** | 5% | BASELINE_MODE=true disables all agents, uses hardcoded fallbacks. Side-by-side shows AI impact. | .env flag, fallback_levels.py, demo toggle |

---

## 11. ANTIGRAVITY INTEGRATION DETAILS

### Development Phase
Full project built inside Google Antigravity using 4 specialized development agents:
- **Backend Architect:** FastAPI routes, Pydantic models, Firebase service, Redis service
- **Flutter Architect:** All screens, navigation, Flame integration, Riverpod providers
- **AI Systems Engineer:** All 5 game agents, Gemini prompts, trace format, fallbacks
- **Debugger:** Integration testing, edge cases, schema validation fixes

### Runtime Phase
Google Gemini (Antigravity's AI model) powers all 5 agents during every gameplay session. Agents are not called once at startup — they are called on every player action (Referee), every enemy turn (Rival), every floor start (LevelGenerator), every story event (Narrative), and every session start (DungeonMaster).

### Artifacts Submitted
All Antigravity session exports in `docs/ANTIGRAVITY_TRACES/`:
- Architecture planning session
- Backend implementation session
- Agent system development session
- Integration and debugging session

---

*This PRD is the source of truth for DungeonMind v2.1.*
*All other docs derive from it. Agents: read this before any task.*
