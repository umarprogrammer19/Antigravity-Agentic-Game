# DungeonMind — Product Requirements Document (PRD)
### Version 2.0 | Google Antigravity Hackathon
### Reference for: ALL agents — read this before ANY task
---

## 1. PRODUCT OVERVIEW

### Product Name
**DungeonMind** — An AI-Powered Roguelike Dungeon Crawler

### One-Line Pitch
A mobile dungeon crawler where five specialized Gemini AI agents serve as your Dungeon Master, enemy brain, storyteller, rule enforcer, and tactical coach — making every run uniquely personalized and every AI decision visible in real time.

### Core Problem Being Solved
Most roguelike games use procedural generation to create variety, but the difficulty never truly adapts to you. A beginner and an expert play through the same statistical distribution. DungeonMind uses AI agents that:
1. **Know your history** — The Dungeon Master has read every run you've ever played
2. **Adapt invisibly** — Difficulty adjusts between sessions without telling you
3. **Show their reasoning** — Every agent decision is streamed to the screen live
4. **Learn mid-game** — Enemy AI reads your tactics and counters them after 3 turns

### Why This Wins the Hackathon
- **Antigravity usage (30% of score):** The entire game was built inside Antigravity using agentic development. Exported artifacts prove it.
- **Agentic innovation (20%):** Five tightly-integrated agents with Redis memory sharing and real-time trace streaming.
- **AI Decision Panel:** Judges can watch AI think in real time. No demo needed — just play the game.
- **Quotable demo moment:** "The AI made 7 decisions before you took your first step."

---

## 2. TARGET USERS

### Primary User: Hackathon Judges
They want to see:
- Evidence of genuine Antigravity agent usage (not just prompting)
- AI that makes non-trivial decisions (not just "I set difficulty to 5")
- A working, playable game (not a demo with mocked responses)
- Traceable reasoning chains they can follow and verify

**What we give them:** Live AI Decision Panel + Trace Viewer screen with full agent reasoning chains including specific data, formulas, and conclusions.

### Secondary User: Mobile Gamers
They want:
- A game that gets harder as they improve and easier when they're stuck
- Feeling like the game "knows them"
- Story and atmosphere, not just mechanics

**What we give them:** DM agent that silently adapts, narrative agent that tells their story.

---

## 3. CORE FEATURES

### F-01: AI Dungeon Master (Session Planner)
Before each run, reads the player's full session history. Computes loss rate, avg floors cleared, favorite death cause. Generates a personalized session plan: difficulty, theme, enemy speed, item drop rate.
**Spec:** docs/AI_BEHAVIOR_SPECS.md — Agent 1

### F-02: Procedural Level Generation
For each floor, generates a unique dungeon layout: grid, walls, enemy/item positions, exit. Validated JSON grid with guaranteed path from start to exit.
**Spec:** docs/AI_BEHAVIOR_SPECS.md — Agent 2

### F-03: Adaptive Enemy AI
Controls each enemy's turn. After 3 moves, reads player's dominant direction, melee/ranged preference, retreat patterns. Overrides base behavior to counter the player.
**Spec:** docs/AI_BEHAVIOR_SPECS.md — Agent 3

### F-04: Live AI Decision Panel (Most Important UI Feature)
Draggable panel at the bottom of the game screen. Shows every AI agent decision in real time. Collapsed: 1-line summary. Expanded: full reasoning + tool call log.
**Spec:** docs/UI_SPECS.md — Screen 4

### F-05: Atmospheric Narrative
Generates 1-2 sentence dark fantasy story text for: session start, floor clears, item finds, boss encounters, player deaths. Specific to theme and player class.
**Spec:** docs/AI_BEHAVIOR_SPECS.md — Agent 4

### F-06: Fair Rule Enforcement
Validates every player action. Standard moves: pure Python < 50ms. Edge cases: Gemini. Never crashes, never softlocks.
**Spec:** docs/AI_BEHAVIOR_SPECS.md — Agent 5

### F-07: Session Trace Viewer
After each run, shows a full log of every AI decision: agent name, reasoning, tool inputs/outputs, decision made, timing. Judge evaluation screen.
**Spec:** docs/UI_SPECS.md — Screen 7

### F-08: Adaptive Post-Game Feedback
After death, the DM agent's reasoning is shown: "You died because X. Next time try Y. Difficulty adjusted."

---

## 4. GAME DESIGN

### Character Classes

| Class | HP | ATK | DEF | Playstyle |
|-------|----|----|-----|-----------|
| Warrior | 150 | 20 | 8 | Melee +50%. Best for beginners. |
| Mage | 80 | 35 | 3 | Range 2 tiles. High damage, fragile. |
| Ranger | 100 | 25 | 5 | Balanced. Dash once per floor. |

### Dungeon Themes

| Theme | Enemies | Difficulty |
|-------|---------|-----------|
| Enchanted Forest | Goblin, Forest Witch, Druid | Easiest |
| Cursed Library | Shadow Mage, Book Golem, Librarian | Medium |
| Volcanic Caves | Fire Elemental, Rock Troll, Lava Sprite | Hardest |

### Win Condition: Survive all 5 floors (Floor 5 = boss floor)
### Loss Condition: Player HP reaches 0

### Score Formula
```
Score = (floors_cleared × 100) + (remaining_hp × 2) + (enemies_killed × 10)
```

---

## 5. TECHNICAL REQUIREMENTS

### Performance Targets

| Operation | Target | Max | On Timeout |
|-----------|--------|-----|-----------|
| DM Agent (session start) | < 3s | 8s | Return fallback |
| Level generation | < 3s | 8s | Return cached/fallback |
| NPC decision | < 1s | 1.5s | Return base_behavior |
| Action validation | < 50ms | 200ms | Pure Python always |
| Narrative | < 2s | 3s | Return hardcoded text |

### Reliability Rules
- Backend NEVER returns 500 — all failures return 200 + `fallback_used: true`
- All async Flutter calls have timeout + loading state + error state
- Every agent has a hardcoded fallback — game playable without AI

### AI API Rules
- All Gemini calls: `response_mime_type="application/json"` + `response_schema`
- All responses validated with Pydantic before use
- Retry once on validation failure, then fallback
- Rate limit: 60 agent calls/player/minute (Redis enforced)

---

## 6. NON-REQUIREMENTS (explicitly out of scope)

```
✗ Multiplayer       ✗ Image assets (colored shapes only)
✗ Sound / music     ✗ In-app purchases
✗ Offline mode      ✗ Tablet optimization
✗ Web version       ✗ More than 5 floors
✗ More than 3 themes or 3 classes
```

---

## 7. USER FLOWS

### New Player First Run
```
Open app → Auth → Character Select → Choose Warrior
→ Loading: DM thinking (0 sessions → difficulty 3, enchanted_forest)
→ Play floor 1 → clear → floor 2 → die on floor 3
→ Death screen → AI feedback → menu shows "1 session, 0 wins"
```

### Returning Player (10 Losses)
```
Open app → Menu shows stats (10 losses)
→ NEW RUN → DM: "loss_rate=1.0 → easy mode (diff 2, enchanted_forest)"
→ Player clears 3 floors → AI panel: "Enemy switched to melee (detected ranged preference)"
→ Win session → post-game: "Next run: difficulty adjusted upward"
```

### Judge Demo (3 Minutes)
```
0:00-0:30  Log in as pre-seeded demo account (10 losses on record)
0:30-1:00  NEW RUN → show Antigravity terminal DM trace
           "loss_rate = 10/10 = 1.00 → difficulty 2 applied"
1:00-2:00  Play floor 1 live with AI Decision Panel updating in real time
           "Enemy learned rush pattern → switched to ranged tactics"
2:00-2:30  Open Trace Viewer → all 7 decisions, beautiful formatted log
           "7 AI decisions before you took your first step"
2:30-3:00  Architecture slide → close: "Remove the AI and the game stops working."
```

---

## 8. FEATURE PRIORITY

### P0 — Must Have (game breaks without)
- Firebase auth, Flame grid, player movement, combat
- RefereeAgent, LevelGeneratorAgent, DungeonMasterAgent
- AI Decision Panel, session save, post-game screen

### P1 — Should Have (score suffers without)
- RivalAgent, NarrativeAgent, Trace Viewer, Leaderboard

### P2 — Nice to Have (polish)
- Combat animations, damage numbers, transition animations

### P3 — Cut if needed
- Sound, achievements, inventory screen

---

## 9. DEMO PREPARATION

### Pre-Seeded Demo Account
Create Firebase account with 10 sessions, 0 wins, 10 losses, avg_floors=2.0, favorite_death=shadow_mage. Ensures DM always demonstrates easy-mode adaptation during demo.

### Backup Plan if Gemini API Down
- Fallbacks produce valid gameplay
- Show `fallback_used: true` in traces as robustness proof
- "The game works even without AI — that's good engineering"

---

## 10. ANTIGRAVITY INTEGRATION

### Development Phase (Antigravity as IDE)
Full project built inside Antigravity using 4 specialized agents:
- Backend Architect: FastAPI + Pydantic + Firebase service
- Flutter Architect: All screens + Flame + navigation
- AI Systems Engineer: All 5 game agents + prompts + traces
- Debugger: Integration + edge cases

### Artifacts Submitted
All Antigravity session exports saved in `docs/ANTIGRAVITY_TRACES/`.

---

*This PRD is the source of truth for DungeonMind. All other docs derive from it.*
