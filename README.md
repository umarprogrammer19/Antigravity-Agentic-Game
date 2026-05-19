# 🏰 DungeonMind
### An AI-Powered Roguelike Dungeon Crawler
**Google Antigravity Hackathon Submission**

---

> *"This isn't a game with AI. This is AI that plays a game with you."*

---

## 🎮 What Is DungeonMind?

DungeonMind is a turn-based roguelike dungeon crawler where **five specialized Gemini AI agents** serve as your personal Dungeon Master, enemy brain, storyteller, referee, and tactical coach — simultaneously.

Every run is uniquely personalized:
- **Struggling?** Your AI Dungeon Master quietly reduces difficulty without telling you
- **Dominating?** Enemies get smarter, faster, and more aggressive
- **Dying to ranged attacks?** Your NPC opponent learns your tactics and adapts
- **Every decision the AI makes is shown to you in real time** — through the live AI Decision Panel

---

## 🤖 The Five AI Agents

| Agent | Role | Model | Called When |
|-------|------|-------|-------------|
| **DungeonMasterAgent** | Analyzes player history, creates personalized session | Gemini Flash Thinking | Once per session start |
| **LevelGeneratorAgent** | Procedurally generates dungeon floors as JSON | Gemini Flash | Once per floor |
| **RivalAgent** | Controls enemy AI, adapts to player tactics | Gemini Flash | Every enemy turn |
| **NarrativeAgent** | Generates story text for key game events | Gemini Flash | Story events |
| **RefereeAgent** | Validates actions, computes combat, grants rewards | Pure Python + Gemini (edge cases) | Every player action |

---

## 🏗️ Architecture

```
Flutter App (mobile-game/)
    │
    │ HTTP REST
    ▼
FastAPI Backend (mobile-game-server/)
    │
    ├── AI Agents ──────────────▶ Gemini API
    ├── Firebase Admin ──────────▶ Firestore + Realtime DB
    └── Redis ───────────────────▶ Session cache + agent memory
```

### Tech Stack

**Mobile:** Flutter 3.x + Flame game engine + Riverpod state management  
**Backend:** Python FastAPI + uvicorn  
**AI:** Google Gemini 2.0 Flash (+ Flash Thinking for DungeonMaster)  
**Database:** Firebase Firestore + Firebase Realtime DB  
**Cache:** Redis (agent working memory, level cache)  
**IDE:** Google Antigravity (agent-first development throughout)

---

## 🔧 How Antigravity Was Used

This project was built **entirely inside Google Antigravity** as the primary development environment.

### Development Phase (Antigravity as IDE)
- **Architecture Agent:** Generated complete project structure from specs
- **Backend Architect Agent:** Scaffolded all FastAPI routes and Pydantic models
- **Flutter Agent:** Built all screens, navigation, and Flame integration
- **AI Systems Agent:** Implemented all 5 game agents with Gemini integration
- **Debugger Agent:** Resolved integration issues and edge cases

### Runtime Phase (Gemini as Game AI)
Antigravity's Gemini model powers the 5 in-game agents at runtime.

### Artifacts Submitted
See `docs/ANTIGRAVITY_TRACES/` for:
- Architecture planning session artifacts
- Backend implementation artifacts
- Agent system development artifacts
- Integration and debugging artifacts

---

## 📁 Project Structure

```
antigravity-game/
├── mobile-game/                    # Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── app/
│   │   │   ├── router.dart         # GoRouter navigation
│   │   │   └── theme.dart          # Dark dungeon design system
│   │   ├── features/
│   │   │   ├── auth/               # Firebase auth
│   │   │   ├── menu/               # Main menu
│   │   │   ├── character_select/   # Class selection
│   │   │   ├── game/               # Flame game + HUD + AI panel
│   │   │   ├── traces/             # AI decision viewer
│   │   │   └── leaderboard/        # Global rankings
│   │   └── services/
│   │       ├── agent_service.dart  # Backend API calls
│   │       └── firebase_service.dart
│   └── pubspec.yaml
│
├── mobile-game-server/             # Python backend
│   ├── main.py                     # FastAPI app
│   ├── agents/
│   │   ├── base_agent.py           # BaseAgent with tracing
│   │   ├── dungeon_master.py       # Session planner
│   │   ├── level_generator.py      # Dungeon architect
│   │   ├── rival_agent.py          # NPC brain
│   │   ├── narrative_agent.py      # Storyteller
│   │   └── referee_agent.py        # Rule enforcer
│   ├── routers/                    # FastAPI routes
│   ├── models/                     # Pydantic schemas
│   ├── services/                   # Firebase + Redis
│   └── fallbacks/                  # Hardcoded safety nets
│
└── docs/                           # All specification documents
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
    └── ANTIGRAVITY_TRACES/
```

---

## 🚀 Setup & Running

### Prerequisites
```
Flutter 3.x (flutter --version)
Python 3.12+ (python --version)
uv package manager (uv --version)
Redis (redis-server)
Firebase project (Firebase Console)
Gemini API key (Google AI Studio)
Google Antigravity (antigravity.google)
```

### Backend Setup
```bash
cd mobile-game-server

# Install dependencies with uv
uv sync

# Create .env file
cp .env.example .env
# Fill in: GEMINI_API_KEY, FIREBASE_CREDENTIALS_PATH, REDIS_URL

# Add Firebase service account
# Download serviceAccountKey.json from Firebase Console
# Place in mobile-game-server/serviceAccountKey.json

# Start Redis
redis-server

# Run backend
uv run uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Verify: http://localhost:8000/docs
```

### Flutter Setup
```bash
cd mobile-game

# Install dependencies
flutter pub get

# Create Firebase config
# Run: flutterfire configure
# OR manually add google-services.json (Android) and GoogleService-Info.plist (iOS)

# Create env config
# lib/config/env.dart — set backendBaseUrl

# Run on Android emulator
flutter run

# Run on physical device
flutter run --release
```

### Environment Variables
```env
# mobile-game-server/.env
GEMINI_API_KEY=your_gemini_api_key_here
FIREBASE_CREDENTIALS_PATH=serviceAccountKey.json
FIREBASE_DATABASE_URL=https://your-project-default-rtdb.firebaseio.com
REDIS_URL=redis://localhost:6379
APP_ENV=development
LOG_LEVEL=INFO
```

---

## 🎯 How to Play

1. **Sign In** — Google or anonymous
2. **Choose Your Class** — Warrior (melee), Mage (ranged), Ranger (balanced)
3. **Wait for Your Dungeon Master** — AI analyzes your history and prepares a personalized run
4. **Explore the Dungeon** — Move with arrow keys/d-pad, move into enemies to attack
5. **Watch the AI Panel** — See every AI decision in real time at the bottom of the screen
6. **Reach the Exit** — Step on the green tile to clear each floor
7. **Survive 5 Floors** — Clear all 5 to win the session
8. **Review AI Decisions** — After each run, see every decision your Dungeon Master made

### Controls
```
Arrow Keys / WASD     → Move player
Move into enemy       → Attack
[MENU button]         → Pause / abandon run
[Drag AI panel up]    → Expand AI decision log
```

---

## 📊 Agent Trace Example

Here's a real example of the DungeonMaster Agent making decisions for a struggling player:

```
SESSION START — Player: warrior, 10 sessions, 2 wins, 8 losses

[DungeonMasterAgent - Step 1 - 10:32:01]
REASONING: "Reading player history. 8 losses, 2 wins across 10 sessions."
TOOL: read_player_history
DECISION: "History loaded. Computing performance category."

[DungeonMasterAgent - Step 2 - 10:32:02]  
REASONING: "loss_rate = 8/10 = 0.80. Exceeds 70% threshold → 'struggling' category.
            Decision matrix requires difficulty 1-4. avg_floors_cleared=2.3, so difficulty 3."
TOOL: compute_difficulty_params  
DECISION: "difficulty=3, enemy_speed=0.8x, item_drop=1.5x. Target: 3-4 floors cleared."

[DungeonMasterAgent - Step 3 - 10:32:02]
REASONING: "Theme history: cursed_library 3 losses, volcanic_caves 2 losses, 
            enchanted_forest 1 win. Struggling players → easiest theme."
TOOL: select_theme
DECISION: "Theme: enchanted_forest. Widest corridors, lowest enemy aggression."

[LevelGeneratorAgent - Step 1 - 10:32:04]
REASONING: "Floor 1, difficulty 3 → 10×10 grid, 3 enemies, 2 items."
TOOL: analyze_level_params → generate_grid → place_entities → validate_level
DECISION: "Level generated. Path valid. Difficulty score: 3.2/10. Est. 20 turns."

[Total: 7 AI decisions made before player takes a single step]
```

---

## 🔍 Key Features for Judges

### 1. Live AI Decision Panel
During gameplay, a draggable panel at the bottom shows every AI agent decision in real time:
- Which agent made the decision
- The exact reasoning (with data)
- What was decided
- Processing time

### 2. Session Trace Viewer
After every run, players can review all AI decisions made during the session — formatted as a beautiful log showing the complete "thought process" of the dungeon.

### 3. Adaptive Difficulty (Invisible to Player)
The DungeonMaster silently adjusts difficulty between sessions based on player history. Players feel the game getting easier or harder — they don't see a "difficulty slider" change.

### 4. NPC Learning
After 3 turns, the RivalAgent reads the player's move patterns and overrides enemy base behavior to counter the player's tactics. A player who always rushes melee will find enemies using ranged attacks.

### 5. Every Run is Different
LevelGeneratorAgent creates a new dungeon layout every time. Same difficulty, different grid, different enemy placement, different items.

---

## 🏆 Evaluation Criteria Alignment

| Criterion | Weight | Our Implementation |
|-----------|--------|--------------------|
| Antigravity Execution | 30% | Full development in Antigravity; exported artifacts in docs/ |
| Gameplay Engagement | 25% | Polished roguelike core loop; adaptive difficulty |
| Agentic Innovation | 20% | 5 specialized agents; NPC tactic learning; live trace panel |
| Technical Polish | 15% | Stable Flutter app; <1s NPC decisions; zero game-breaking bugs |
| Concept & Originality | 10% | "AI as Dungeon Master" framing; real-time reasoning visibility |

---

## 📝 Assumptions & Limitations

- All enemy/player art uses colored rectangles (no image assets) — chosen intentionally for performance
- Multiplayer is not implemented — single-player only
- NPC tactic learning requires 3+ turns of data — first 3 turns use base behavior
- Gemini API latency: 1-3 seconds for level generation (shown as intentional "dungeon shifting" animation)
- Redis is required locally — cloud Redis for production deployment
- Demo uses pre-seeded player account with 10 losses for optimal AI adaptation demonstration

---

## 🛠️ Built With Google Antigravity

```
Development Environment: Google Antigravity (agent-first IDE)
AI Model: Gemini 2.0 Flash + Gemini 2.0 Flash Thinking
Backend: Python FastAPI (uv package manager)
Mobile: Flutter + Flame game engine
Database: Firebase (Firestore + Realtime DB)
Cache: Redis
State Management: Riverpod
Navigation: GoRouter
Agent Framework: LangChain + Google Generative AI SDK
```

---

*DungeonMind — Where the AI thinks so the dungeon breathes.*  
*Built solo using Google Antigravity | Google Antigravity Hackathon 2026*
