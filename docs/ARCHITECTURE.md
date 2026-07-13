# DungeonMind — System Architecture Document
### Read by ALL Antigravity agents before starting any task
### Reference for: Backend Architect, Flutter Architect, AI Systems Engineer
---

## ARCHITECTURE OVERVIEW

DungeonMind uses a **3-tier mobile architecture**:

```
┌────────────────────────────────────────────────────────────────────┐
│                     FLUTTER APP  (mobile-game/)                    │
│                                                                    │
│  Screens: Auth → Menu → CharSelect → Game → Result → Traces        │
│  State:   Riverpod (authProvider, playerProvider, gameStateProvider│
│            sessionProvider, traceProvider)                         │
│  Engine:  Flame (DungeonGame, TileMapComponent, PlayerComponent,   │
│            EnemyComponent, HUDComponent)                           │
│  Router:  GoRouter (/auth /menu /character-select /game /result    │
│            /traces/:id /leaderboard)                               │
│  HTTP:    AgentService → FastAPI backend                           │
│  Realtime:Firebase Realtime DB listener → ai_status updates        │
└────────────────────────────┬───────────────────────────────────────┘
                             │ HTTP REST (JSON)
                             │ Port 8000
┌────────────────────────────▼─────────────────────────────────────┐
│                   FASTAPI BACKEND  (mobile-game-server/)           │
│                                                                    │
│  Routers: /agent/* /traces/* /players/* /health                   │
│  Agents:  DungeonMasterAgent  LevelGeneratorAgent  RivalAgent     │
│           NarrativeAgent  RefereeAgent  (all inherit BaseAgent)   │
│  Services:FirebaseService  RedisService  SessionService            │
│  Models:  Pydantic (request/response/game schemas)                 │
│  Fallbacks:FALLBACK_SESSION_PLAN  FALLBACK_LEVELS  NARRATIVES     │
└──────┬──────────────────────────┬───────────────────────────────┘
       │ google-generativeai SDK  │ Firebase Admin + redis.asyncio
       │                          │
┌──────▼────────┐  ┌─────────────▼───────────────────────────────┐
│  GEMINI API   │  │  FIREBASE + REDIS                             │
│               │  │                                               │
│ flash-thinking│  │  Firestore: players/{uid}/stats              │
│ (DM agent)    │  │             players/{uid}/sessions/{id}       │
│               │  │             traces/{id}/entries/*             │
│ flash         │  │             levels/{hash}  leaderboard/{uid} │
│ (all others)  │  │                                               │
└───────────────┘  │  Realtime DB: /sessions/{id}/live_state      │
                   │  Redis:  session cache, level cache,          │
                   │          player tactics, rate limiting         │
                   └─────────────────────────────────────────────┘
```

---

## DIRECTORY STRUCTURE

```
antigravity-game/
│
├── mobile-game/                          ← Flutter project root
│   ├── pubspec.yaml                      ← Dependencies: flame, riverpod, go_router, firebase, http
│   └── lib/
│       ├── main.dart                     ← Firebase init, ProviderScope, MaterialApp.router
│       ├── app/
│       │   ├── router.dart               ← GoRouter: all routes + auth redirect guard
│       │   └── theme.dart                ← DungeonColors, DungeonText, DungeonSpacing
│       ├── features/
│       │   ├── auth/
│       │   │   └── auth_screen.dart
│       │   ├── menu/
│       │   │   └── main_menu_screen.dart
│       │   ├── character_select/
│       │   │   └── character_select_screen.dart
│       │   ├── game/
│       │   │   ├── game_screen.dart      ← Stack: GameWidget + HUD overlay + AI panel + d-pad
│       │   │   ├── flame/
│       │   │   │   ├── dungeon_game.dart        ← FlameGame root
│       │   │   │   ├── game_controller.dart     ← Local turn logic + damage formula
│       │   │   │   └── components/
│       │   │   │       ├── tile_map_component.dart
│       │   │   │       ├── player_component.dart
│       │   │   │       ├── enemy_component.dart
│       │   │   │       └── hud_component.dart
│       │   │   └── widgets/
│       │   │       ├── ai_decision_panel.dart   ← Most important UI widget
│       │   │       └── dpad_controls.dart
│       │   ├── result/
│       │   │   └── post_game_screen.dart
│       │   ├── traces/
│       │   │   └── trace_viewer_screen.dart
│       │   └── leaderboard/
│       │       └── leaderboard_screen.dart
│       ├── models/                       ← Dart model classes (fromJson)
│       │   ├── session_plan.dart
│       │   ├── level_schema.dart
│       │   ├── enemy_action.dart
│       │   ├── action_result.dart
│       │   ├── narrative_response.dart
│       │   └── trace_entry.dart
│       ├── providers/
│       │   ├── auth_provider.dart
│       │   ├── player_provider.dart
│       │   ├── session_provider.dart
│       │   ├── game_state_provider.dart  ← Main game state machine
│       │   └── trace_provider.dart
│       └── services/
│           ├── agent_service.dart        ← All HTTP calls to backend
│           └── firebase_service.dart     ← Firebase reads/writes (Flutter side)
│
├── mobile-game-server/                   ← Python FastAPI project root
│   ├── pyproject.toml                    ← uv managed: fastapi, uvicorn, google-generativeai,
│   │                                        firebase-admin, redis, pydantic, python-dotenv
│   ├── .env                              ← GEMINI_API_KEY, FIREBASE_CREDENTIALS_PATH, REDIS_URL
│   ├── serviceAccountKey.json            ← Firebase Admin credentials (gitignored)
│   ├── main.py                           ← FastAPI app, CORS, routers, exception handler
│   ├── config.py                         ← Settings, Firebase init, Redis init, Gemini init
│   ├── exceptions.py                     ← GeminiCallError, AgentValidationError, AgentTimeoutError
│   ├── agents/
│   │   ├── __init__.py
│   │   ├── base_agent.py                 ← BaseAgent: tracing, Gemini client, JSON parsing
│   │   ├── dungeon_master.py             ← DungeonMasterAgent
│   │   ├── level_generator.py            ← LevelGeneratorAgent
│   │   ├── rival_agent.py               ← RivalAgent
│   │   ├── narrative_agent.py            ← NarrativeAgent
│   │   └── referee_agent.py              ← RefereeAgent
│   ├── routers/
│   │   ├── agents.py                     ← POST /agent/* routes
│   │   ├── traces.py                     ← GET /traces/{id}
│   │   ├── players.py                    ← GET+POST /players/{uid}/*
│   │   └── health.py                     ← GET /health
│   ├── models/
│   │   ├── requests.py                   ← Pydantic request models
│   │   ├── responses.py                  ← Pydantic response models
│   │   └── game_schemas.py               ← SessionPlan, LevelSchema, EnemyAction, ActionResult, etc.
│   ├── services/
│   │   ├── firebase_service.py           ← Firestore + Realtime DB operations
│   │   └── redis_service.py              ← All Redis cache operations
│   ├── fallbacks/
│   │   ├── fallback_levels.py            ← 3 hardcoded LevelSchema (one per theme)
│   │   └── fallback_responses.py         ← FALLBACK_SESSION_PLAN, NARRATIVE_FALLBACKS
│   └── utils/
│       └── validators.py                 ← validate_level_playable, validate_no_enemy_on_start
│
└── docs/                                 ← All specification documents
    ├── PRD.md                            ← Product requirements (this project's what/why)
    ├── ARCHITECTURE.md                   ← This file
    ├── GAMEPLAY_LOOP.md                  ← Game rules, turn structure, combat formulas
    ├── AI_BEHAVIOR_SPECS.md              ← All 5 agent inputs/outputs/rules/fallbacks
    ├── PROMPT_SPECS.md                   ← Exact Gemini system prompts and user prompt templates
    ├── API_CONTRACTS.md                  ← All 10 routes with full JSON request/response
    ├── DATABASE_SCHEMA.md                ← Firestore collections, Redis keys, Realtime DB
    ├── JSON_SCHEMAS.md                   ← Pydantic models + Dart models for all data structures
    ├── UI_SPECS.md                       ← Design system, 8 screen layouts, component specs
    ├── TRACE_FORMAT.md                   ← TraceEntry schema, BaseAgent impl, trace examples
    ├── ANTIGRAVITY_PROMPTS.md            ← Copy-paste prompt library for every build phase
    ├── QUICK_REF.md                      ← One-page cheat sheet of everything
    └── ANTIGRAVITY_TRACES/              ← Export Antigravity session artifacts here
```

---

## NAMING CONVENTIONS

### Python (Backend)
```python
Files:         snake_case.py          (dungeon_master.py)
Classes:       PascalCase             (DungeonMasterAgent)
Methods:       snake_case()           (get_player_history())
Constants:     SCREAMING_SNAKE_CASE   (FALLBACK_SESSION_PLAN)
Async:         prefix with async      (async def run(...))
Private:       prefix with _          (_call_gemini(), _traces)
```

### Dart (Flutter)
```dart
Files:         snake_case.dart        (agent_service.dart)
Classes:       PascalCase             (AgentService)
Methods:       camelCase()            (startSession())
Constants:     camelCase              (baseUrl)
Providers:     camelCase + Provider   (gameStateProvider)
Notifiers:     PascalCase + Notifier  (GameStateNotifier)
```

### API
```
Endpoints:   kebab-case              /agent/dungeon-master
JSON fields: snake_case              session_id, player_class
```

### Firebase
```
Collections: camelCase              players, sessions, traces
Documents:   use meaningful IDs     players/{uid}, sessions/{session_id}
Fields:      camelCase in Flutter,  snake_case from Python admin SDK
```

---

## DATA FLOW: SESSION START

```
Flutter                     FastAPI                      External
   │                           │                            │
   │──POST /agent/dungeon-master──►│                        │
   │  {player_id, player_class}    │                        │
   │                           │──check Redis────────────►Redis
   │                           │  "player:{uid}:history"    │
   │                           │◄─cache miss────────────────│
   │                           │──read Firestore─────────►Firestore
   │                           │  players/{uid}/stats       │
   │                           │◄─history data──────────────│
   │                           │──DungeonMasterAgent.run()  │
   │                           │──send to Gemini──────────►Gemini API
   │                           │  (flash-thinking model)    │
   │                           │◄─SessionPlan JSON──────────│
   │                           │──validate Pydantic         │
   │                           │──save traces (background)─►Firestore
   │                           │──cache dm_plan────────────►Redis
   │                           │──update Realtime DB───────►Firebase RTDB
   │◄──200 SessionPlan JSON────│                            │
   │                           │                            │
   │  (Immediately after)      │                            │
   │──POST /agent/generate-level──►│                        │
   │  {session_id, floor=1, ...}   │                        │
   │                           │──check Redis level cache──►Redis
   │                           │◄─cache miss────────────────│
   │                           │──LevelGeneratorAgent.run() │
   │                           │──send to Gemini──────────►Gemini API
   │                           │◄─LevelSchema JSON──────────│
   │                           │──validate + path check     │
   │                           │──cache level──────────────►Redis
   │◄──200 LevelSchema JSON────│                            │
   │                           │                            │
   [Flutter renders level in Flame. Game starts.]
```

---

## DATA FLOW: PLAYER TURN

```
Flutter (Flame)               FastAPI                      Firebase RTDB
   │                              │                            │
   [Player taps d-pad "right"]   │                            │
   │──predict move locally────    │                            │
   │  (GameController fast-path)  │                            │
   │──POST /agent/validate-action─►│                           │
   │  {action: {type:"move",       │                           │
   │   direction:"right"}}         │                           │
   │                              │──RefereeAgent.run()        │
   │                              │  (pure Python, no Gemini)  │
   │◄──200 ActionResult (8ms)─────│                            │
   │  {result_type:"moved",        │                           │
   │   new_player_position:[3,6]}  │                           │
   │                              │                            │
   [Apply result to Flame state]  │                            │
   [Animate player moving]        │                            │
   │                              │                            │
   [Enemy turn begins]            │                            │
   │──set aiIsThinking=true───────►Firebase RTDB listener      │
   │  (Flutter Realtime DB write) │                            │
   │──POST /agent/npc-decision────►│                           │
   │  (for enemy e1)               │                           │
   │                              │──RivalAgent.run()          │
   │                              │──check Redis npc cache──►Redis
   │                              │◄─cache miss────────────────│
   │                              │──send to Gemini──────────►Gemini
   │                              │◄─EnemyAction JSON──────────│
   │                              │──cache result─────────────►Redis
   │                              │──update Realtime DB───────►Firebase RTDB
   │◄──200 EnemyAction (780ms)────│                            │
   │  {action_type:"attack",       │                    ┌──────▼──────────┐
   │   reasoning:"Player adjacent"}│                    │AI Decision Panel│
   │                              │                    │ auto-updates!   │
   [Apply enemy attack to game]   │                    └─────────────────┘
   [Animate damage]               │                            │
   │──set aiIsThinking=false       │                            │
```

---

## AGENT ARCHITECTURE

### BaseAgent (Inheritance)
```python
BaseAgent
├── DungeonMasterAgent   (model: flash-thinking, temp: 0.4)
├── LevelGeneratorAgent  (model: flash, temp: 0.7)
├── RivalAgent           (model: flash, temp: 0.3)
├── NarrativeAgent       (model: flash, temp: 0.9)
└── RefereeAgent         (model: flash, temp: 0.1, mostly pure Python)
```

### Agent Isolation Rule
Agents do NOT call each other. All data flows through FastAPI routes. The Flutter app orchestrates the sequence:
```
startSession() → generateLevel() → [gameplay loop: validateAction() + npcDecision()] → saveSession()
```

### Shared Memory (Redis)
Agents share state via Redis (not direct calls):
```
DungeonMasterAgent writes → session:{id}:dm_plan
LevelGeneratorAgent reads → session:{id}:dm_plan (to get difficulty/theme)
RivalAgent reads          → session:{id}:player_tactics
RivalAgent writes         → session:{id}:player_tactics (updated profile)
All agents write          → traces/{session_id}/entries/* (via Firestore, background)
```

---

## FLUTTER STATE MANAGEMENT

### Provider Graph
```dart
authProvider (StreamProvider<User?>)
    └── playerProvider (AsyncNotifierProvider<PlayerModel>)
            └── sessionProvider (StateNotifierProvider<SessionModel>)
                    └── gameStateProvider (StateNotifierProvider<GameState>)
                            └── traceProvider (StateNotifierProvider<List<TraceEntry>>)
```

### GameState Machine
```dart
enum GameStatus { loading, playing, enemyTurn, animating, transition, gameOverWin, gameOverLose }
enum TurnPhase { playerTurn, processing, enemyTurn, animating }

class GameState {
  GameStatus status;
  SessionPlan? sessionPlan;
  LevelSchema? currentLevel;
  PlayerState playerState;
  List<EnemyState> enemies;
  List<ItemState> itemsOnBoard;
  TurnPhase turnPhase;
  ActionResult? lastActionResult;
  bool aiIsThinking;
  String aiLastDecision;
  List<TraceEntry> sessionTraces;
}
```

---

## FIREBASE REALTIME DB (Live AI Panel)

The Realtime DB is used for ONE purpose: streaming AI status to the Flutter app.

```json
/sessions/{session_id}/live_state/ai_status: {
  "is_thinking": false,
  "last_agent": "RivalAgent",
  "last_decision_summary": "Goblin flanked right — detected rush pattern",
  "last_updated": 1716000000000
}
```

Flutter listens to this path and updates the AI Decision Panel in < 100ms.

---

## ERROR HANDLING STRATEGY

### Backend
```
Every route: try/except around entire handler
Agent failure: log error + return fallback response with fallback_used=true
Firebase failure: log error + return cached data or empty response
Redis failure: log error + continue without cache (degraded performance, not crash)
Gemini 429 (rate limit): wait 1s + retry once, then fallback
Gemini 503 (service unavailable): immediately use fallback
JSON validation failure: retry once with corrective prompt, then fallback
```

### Flutter
```
HTTP timeout (10s): show "AI taking longer than usual..." + use last known state
HTTP error (non-200): show SnackBar + continue game with local state
Firebase auth failure: navigate to /auth
Flame render error: catch in game loop, log to console, skip frame
```

---

## TECHNOLOGY DECISIONS

| Decision | Chosen | Rejected | Reason |
|----------|--------|---------|--------|
| Mobile framework | Flutter + Flame | React Native, Unity | Flame is Flutter-native, no separate game engine setup |
| State management | Riverpod | Bloc, Provider | Current Flutter standard, code generation, clean async |
| Navigation | GoRouter | Navigator 2.0 | Declarative, handles auth redirect out of the box |
| Backend language | Python FastAPI | Node.js, Go | Python AI libraries, async, auto-docs, fastest to write |
| Package manager | uv | pip, poetry | Fastest Python resolver, reproducible builds |
| AI SDK | google-generativeai | LangChain | Direct SDK = fewer dependencies, full control |
| Database | Firebase | Supabase, PlanetScale | Flutter SDK native, Realtime DB built-in |
| Cache | Redis | In-memory | Survives restarts, shared across workers |
| Game rendering | Colored Paint rects | Image sprites | Zero asset prep time, still looks professional |
| Gemini models | flash-thinking (DM) + flash (rest) | pro, nano | flash-thinking best reasoning; flash fastest for real-time |

---

## DEPENDENCIES

### Python (mobile-game-server/pyproject.toml)
```toml
[dependencies]
fastapi = ">=0.115"
uvicorn = {extras = ["standard"]}
google-generativeai = ">=0.8"
firebase-admin = ">=6.5"
redis = {extras = ["asyncio"]}
pydantic = ">=2.0"
python-dotenv = ">=1.0"
```

### Dart (mobile-game/pubspec.yaml)
```yaml
dependencies:
  flutter: sdk: flutter
  flame: ^1.18.0
  flutter_riverpod: ^2.5.0
  go_router: ^14.0.0
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  firebase_database: ^11.0.0
  http: ^1.2.0
  google_fonts: ^6.2.0
```

---

## ANTIGRAVITY DEVELOPMENT SETUP

### Agent Assignments
```
Agent 1 "Backend Architect":
  Workspace: mobile-game-server/
  Context files: ARCHITECTURE.md, API_CONTRACTS.md, DATABASE_SCHEMA.md
  Owns: main.py, config.py, all routers, Pydantic models, Firebase service, Redis service

Agent 2 "Flutter Architect":
  Workspace: mobile-game/lib/
  Context files: ARCHITECTURE.md, UI_SPECS.md, API_CONTRACTS.md
  Owns: all screens, providers, services, router, theme

Agent 3 "AI Systems Engineer":
  Workspace: mobile-game-server/agents/
  Context files: AI_BEHAVIOR_SPECS.md, PROMPT_SPECS.md, TRACE_FORMAT.md
  Owns: all 5 agent classes, BaseAgent, fallbacks/

Agent 4 "Debugger" (spawn on demand):
  Workspace: specific file with bug
  Context: only the broken file + error message
  Owns: nothing permanently — targeted fixes only
```

### Concurrent Agent Rule
**NEVER run 2 agents on the same file simultaneously.**
Git commit after every successful agent session.
Always paste ARCHITECTURE.md as context at the start of each session.

---

*All agents must read this document completely before starting any task.*
*If something in another doc contradicts this, flag it — this doc defines the architecture.*
