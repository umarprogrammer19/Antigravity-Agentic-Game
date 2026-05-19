# DUNGEONMIND — SOLO DEVELOPER MASTER PLAN
### Google Antigravity Hackathon | Complete Build Guide for Solo Developer
> **Game Type: AI Roguelike Dungeon Crawler (Turn-Based, 2D, Flutter + Flame)**
> **Stack: Flutter + Flame | FastAPI + uv | Firebase | Gemini API | Redis**
> **IDE: Google Antigravity (agent-first development throughout)**

---

## SECTION 1 — SOLO DEVELOPMENT STRATEGY

### The Solo Developer's Core Philosophy

You are not a programmer in this hackathon. You are an **architect and reviewer**.
Your job is to write specifications, review Antigravity's output, and glue systems together.
Every line of boilerplate should be Antigravity's job. Every architectural decision is yours.

> Rule: If you are typing more than 20 lines of code manually, you are doing it wrong.
> Ask Antigravity to write it. Your job is to review, test, and direct.

### What Antigravity Should Automate (Everything Routine)

- All Flutter screen scaffolding (screens, widgets, navigation)
- All FastAPI route boilerplate (request/response models, error handling)
- All Pydantic schema definitions
- Firebase service layer (CRUD operations)
- All agent class boilerplate (LangChain setup, tool registration)
- Unit test generation
- README and documentation generation
- Refactoring for consistency
- Debugging specific error messages

### What You Should Do Manually (Architecture + Judgment)

- Writing specifications before Antigravity codes (ALWAYS write specs first)
- Reviewing every AI-generated file before moving forward
- Designing the Gemini prompt for each agent (Antigravity writes code, YOU write prompts)
- Deciding which feature to build next
- Integration testing (run the app yourself, catch edge cases)
- Game balance decisions (how hard is too hard?)
- Demo scripting and video recording

### How to Divide Work Between Antigravity Agents

Run agents in this way to avoid conflicts:

```
NEVER run 2 agents editing the same file simultaneously.
NEVER run frontend and backend agents on the same task.
ALWAYS finish + review one agent's work before starting the next.

Safe parallel:
  Agent A: Writing Flutter screen
  Agent B: Writing FastAPI route (different files, no conflict)

Unsafe parallel:
  Agent A: Editing game_state.dart
  Agent B: Also editing game_state.dart (CONFLICT — don't do this)
```

### How to Avoid Chaos with AI-Generated Code

**The Spec-First Rule:**
Before starting ANY Antigravity agent session, write a 5-10 line specification of what
you want. Paste it as context at the start of the prompt. This prevents hallucinations
and keeps the agent focused.

**The Review Gate:**
After every agent session, read the generated files. Don't run the next agent until
you've verified the output is correct. 15 minutes of review saves 2 hours of debugging.

**The Single Responsibility Rule:**
Each agent session should have ONE clear output. Not "build the entire game" but
"build the LevelGeneratorAgent class with these 3 tools."

**File Ownership:**
Mentally assign every file to one system. If Antigravity tries to edit a file it doesn't own,
stop it and redirect.

### How to Maintain Architecture Consistency

Create `docs/ARCHITECTURE.md` FIRST. Every Antigravity agent session starts by giving
the agent this file as context: "Here is our architecture. Read it. Your task fits within it."

This prevents the agent from inventing its own patterns.

### How to Avoid Token/Context Issues

- Keep each agent session focused on 1 module (one file or one feature)
- For large files, give Antigravity a specific section: "Edit only the DungeonMasterAgent class"
- After every 3-4 agent sessions, start a new conversation (context gets stale)
- Keep your spec docs short and precise — 1 page per module is better than 5 pages

### How to Structure Development Sessions

Each session should follow this pattern:
```
[SESSION START]
1. Write a 5-line spec of what this session produces
2. Open the relevant files in Antigravity
3. Paste architecture context + spec into agent prompt
4. Let agent generate
5. Review output (15 min)
6. Run the app/server to verify
7. Commit to git: git commit -m "feat: [what was built]"
8. [SESSION END]
```

One session = one commit. Never commit unreviewed code.

---

## SECTION 2 — HOW TO USE GOOGLE ANTIGRAVITY PROPERLY

### Understanding Antigravity's Agent Types

Antigravity has two modes you should use:

**1. Editor Mode (for precise, targeted work)**
Use when: editing a specific file, fixing a bug, adding a function
Prompt style: Very specific. "In `agents/level_generator.py`, add a tool called
`validate_level_balance` that checks if enemy count <= 8 and returns a score from 0-10."

**2. Manager View / Mission Control (for multi-file tasks)**
Use when: scaffolding a new module, generating multiple related files at once
Prompt style: Task-oriented. "Create the complete FastAPI router for /agent/* endpoints.
Generate: routers/agents.py, models/agent_request.py, models/agent_response.py."

### Recommended Antigravity Agent Setup

Create these persistent agents in Antigravity's Mission Control:

```
AGENT 1: "Flutter Architect"
  Workspace: mobile-game/lib/
  Context files: docs/UI_SPECS.md, docs/GAMEPLAY_LOOP.md
  Responsibility: All Flutter code (screens, widgets, services, Flame components)

AGENT 2: "Backend Architect"  
  Workspace: mobile-game-server/
  Context files: docs/ARCHITECTURE.md, docs/API_CONTRACTS.md
  Responsibility: FastAPI routes, services, schemas

AGENT 3: "AI Systems Engineer"
  Workspace: mobile-game-server/agents/
  Context files: docs/AI_BEHAVIOR_SPECS.md, docs/PROMPT_SPECS.md
  Responsibility: All agent classes, tools, Gemini integration

AGENT 4: "Debugger"
  Workspace: entire project
  Context files: current error + relevant file
  Responsibility: Fix specific bugs (spawn only when needed)
```

### Recommended Workflow Setup

Workflow 1: "New Feature"
```
1. Update relevant spec doc
2. Prompt Flutter Architect (if frontend) OR Backend Architect (if backend)
3. Review output
4. Prompt AI Systems Engineer if AI integration needed
5. Integration test
6. Commit
```

Workflow 2: "Bug Fix"
```
1. Copy exact error message + stack trace
2. Open Debugger agent
3. Paste: "Error: [paste error]. File: [file]. Fix this."
4. Review fix
5. Test
6. Commit
```

Workflow 3: "Refactor"
```
1. Open relevant agent
2. Prompt: "Refactor [file] to follow the pattern in [reference file].
   Do not change behavior. Improve readability and consistency."
3. Review line by line
4. Commit
```

### How Traces/Artifacts Are Generated

Antigravity automatically generates Artifacts for every agent task:
- **Task List**: What the agent planned to do
- **Implementation Plan**: How it approached the task
- **Browser Recordings**: If agent tested in browser
- **Code Diffs**: Exact changes made

**For judge submission:** Export these artifacts from every major agent session.
Especially: DungeonMasterAgent creation, Level Generator creation, any architecture-level task.

Store exported artifacts in: `docs/ANTIGRAVITY_TRACES/`

### How to Maximize Antigravity Score (30% of judging)

Judges look for:
1. **Depth** — did you use Antigravity for core logic or just syntax help?
2. **Traces** — do you have agent artifacts showing planning + execution?
3. **Non-superficial** — Antigravity must be central, not decorative

To maximize:
- Use Mission Control for at least 3 major multi-file tasks
- Export and submit artifacts from: architecture session, agent system session, integration session
- In your README: "We used Antigravity to architect, implement, and refactor [specific systems]"
- In your demo video: show Antigravity IDE with an agent working (30 seconds is enough)

### Recommended Workspace Organization

```
antigravity-game/           ← Open THIS folder in Antigravity
├── mobile-game/            ← Flutter workspace (Agent 1 owns this)
├── mobile-game-server/     ← Backend workspace (Agents 2+3 own this)
└── docs/                   ← Spec docs (ALL agents read these)
    └── ANTIGRAVITY_TRACES/ ← Export artifacts here
```

---

## SECTION 3 — PROJECT DOCUMENTATION STRUCTURE

### Documents to Create BEFORE Coding

Create these in order. Each one feeds into the next.

```
docs/
├── PRD.md                    ← What we're building + why
├── ARCHITECTURE.md           ← Full system design
├── GAMEPLAY_LOOP.md          ← Exact game mechanics
├── AI_BEHAVIOR_SPECS.md      ← What each AI agent does
├── PROMPT_SPECS.md           ← Exact Gemini prompts
├── API_CONTRACTS.md          ← All API routes + request/response
├── DATABASE_SCHEMA.md        ← Firestore + Redis schema
├── JSON_SCHEMAS.md           ← Level, session, trace JSON formats
├── UI_SPECS.md               ← Screen layouts + component specs
├── TRACE_FORMAT.md           ← Agent trace log format
└── ANTIGRAVITY_TRACES/       ← Exported Antigravity artifacts
    ├── session_01_architecture.json
    ├── session_02_backend_scaffold.json
    └── session_03_agent_system.json
```

**Which documents agents should always receive as context:**

| Agent | Context Documents |
|-------|------------------|
| Flutter Architect | ARCHITECTURE.md, UI_SPECS.md, GAMEPLAY_LOOP.md, JSON_SCHEMAS.md |
| Backend Architect | ARCHITECTURE.md, API_CONTRACTS.md, DATABASE_SCHEMA.md |
| AI Systems Engineer | AI_BEHAVIOR_SPECS.md, PROMPT_SPECS.md, JSON_SCHEMAS.md |
| Debugger | Only the error + the specific file |

---

## SECTION 4 — FULL DEVELOPMENT ROADMAP

### PHASE 0 — Documentation + Setup (Day 0, ~3 hours)
**Objectives:** Create all spec docs, verify project setup, configure Antigravity

Tasks:
- [ ] Create all docs/ files (use this plan as base)
- [ ] Verify `flutter create mobile-game` runs correctly
- [ ] Verify `uv init mobile-game-server` is correct
- [ ] Add pubspec.yaml dependencies (flame, firebase, http, riverpod)
- [ ] Add pyproject.toml dependencies (fastapi, uvicorn, google-generativeai, langchain, redis, firebase-admin)
- [ ] Create .env file for secrets
- [ ] Create .gitignore
- [ ] Initialize git repo, first commit

**Antigravity Prompt:**
```
Read docs/ARCHITECTURE.md. 

Task: Set up the complete dependency configuration for this project.

For mobile-game/pubspec.yaml, add these dependencies:
- flame: ^1.18.0
- firebase_core, firebase_auth, cloud_firestore, firebase_database
- flutter_riverpod
- http
- go_router

For mobile-game-server/pyproject.toml, add:
- fastapi, uvicorn[standard]
- google-generativeai
- langchain, langchain-google-genai
- redis
- firebase-admin
- pydantic
- python-dotenv

Generate both complete config files.
```

**Manual Verification:** Run `flutter pub get` and `uv sync`. Fix any version conflicts.

---

### PHASE 1 — Backend Foundation (Day 1, Morning, ~4 hours)
**Objectives:** Working FastAPI server with all routes stubbed, schemas defined

Tasks:
- [ ] FastAPI main.py with CORS, middleware, router mounting
- [ ] All Pydantic schemas (AgentRequest, AgentResponse, LevelSchema, TraceLog)
- [ ] All route stubs returning mock data (no AI yet)
- [ ] Firebase Admin SDK initialization
- [ ] Redis client setup
- [ ] Health check endpoint
- [ ] Basic logging config

**Antigravity Prompt:**
```
Read docs/API_CONTRACTS.md and docs/DATABASE_SCHEMA.md and docs/JSON_SCHEMAS.md.

Task: Scaffold the complete FastAPI backend for DungeonMind.

Create:
1. mobile-game-server/main.py — FastAPI app with CORS, logging, router mounting
2. mobile-game-server/config.py — env vars, Firebase init, Redis client
3. mobile-game-server/models/ — all Pydantic models from API_CONTRACTS.md
4. mobile-game-server/routers/agents.py — all /agent/* routes returning MOCK data
5. mobile-game-server/routers/traces.py — GET /traces/{session_id}

All routes should return hardcoded mock responses for now.
Add comprehensive docstrings to every function.
Use async/await throughout.
```

**Expected Output:** `uvicorn main:app --reload` starts. All routes return 200 with mock data.
**Manual Verification:** Open http://localhost:8000/docs — verify all routes visible.

---

### PHASE 2 — Flutter Foundation (Day 1, Afternoon, ~4 hours)
**Objectives:** Working Flutter app with all screens, navigation, Firebase auth

Tasks:
- [ ] App theme + colors
- [ ] GoRouter navigation setup
- [ ] Firebase initialization
- [ ] Auth screen (Google + Anonymous login)
- [ ] Main menu screen
- [ ] Character selection screen
- [ ] Placeholder game screen
- [ ] Riverpod providers for auth state + player state
- [ ] AgentService (Dart class calling backend API)

**Antigravity Prompt:**
```
Read docs/UI_SPECS.md, docs/ARCHITECTURE.md, and docs/GAMEPLAY_LOOP.md.

Task: Scaffold the complete Flutter app for DungeonMind.

Create:
1. lib/main.dart — Firebase init, Riverpod scope, app entry
2. lib/app/router.dart — GoRouter with routes: /, /auth, /menu, /character-select, /game, /traces
3. lib/app/theme.dart — Dark dungeon theme (dark purples, golds, reds)
4. lib/features/auth/ — auth_screen.dart, auth_provider.dart, auth_service.dart
5. lib/features/menu/ — main_menu_screen.dart with: NEW RUN, LEADERBOARD, LAST RUN buttons
6. lib/features/character_select/ — character_select_screen.dart (3 classes: Warrior/Mage/Ranger)
7. lib/features/game/ — game_screen.dart (placeholder with "Game Coming Soon")
8. lib/services/agent_service.dart — Dart class with async methods for each agent endpoint
9. lib/providers/player_provider.dart — Riverpod provider for player state

Use Material 3. Dark theme. Fantasy aesthetic.
All screens should navigate correctly.
Auth screen should support Google Sign In AND anonymous login.
```

**Expected Output:** App runs on emulator. Can log in, see menu, select character.
**Manual Verification:** Run on Android emulator. Test both auth methods.

---

### PHASE 3 — Flame Game Engine (Day 1, Evening, ~5 hours)
**Objectives:** Playable dungeon grid with player movement and basic enemy

Tasks:
- [ ] DungeonGame class (FlameGame)
- [ ] TileMapComponent (renders 15x15 grid)
- [ ] PlayerComponent (movement, health)
- [ ] EnemyComponent (placeholder, no AI yet)
- [ ] HUDComponent (health bar, floor number, turn counter)
- [ ] Basic combat (click to attack adjacent enemy)
- [ ] Win/lose detection (reach exit OR hp <= 0)
- [ ] Hard-coded test level JSON (no AI yet)

**Antigravity Prompt:**
```
Read docs/GAMEPLAY_LOOP.md and docs/JSON_SCHEMAS.md (Level schema section).

Task: Implement the Flame game engine for DungeonMind.

Create:
1. lib/features/game/flame/dungeon_game.dart — FlameGame subclass, initializes components
2. lib/features/game/flame/components/tile_map_component.dart — Renders 15x15 grid from level JSON. 
   Tile types: 0=wall(dark), 1=floor(brown), 2=exit(green glow). Use colored rectangles, no sprites.
3. lib/features/game/flame/components/player_component.dart — Blue square. WASD/arrow key movement.
   Has hp, max_hp, attack_damage properties.
4. lib/features/game/flame/components/enemy_component.dart — Red square. Placeholder.
   Has hp, attack_damage. Dies when hp <= 0. Disappears from map.
5. lib/features/game/flame/components/hud_component.dart — Fixed overlay showing:
   HP bar (red), Floor number, Turn count, "AI THINKING" indicator (toggleable)
6. lib/features/game/flame/game_controller.dart — Handles: turn processing, combat calculation,
   win detection (player reaches exit), lose detection (player hp <= 0)

Combat rules (simple):
- Player moves into enemy = attack (player_damage - enemy_defense = damage)
- After player turn, each enemy moves 1 tile toward player

Use this hardcoded level JSON for testing:
{
  "level_id": "test_001",
  "grid": [[0,0,0,0,0],[0,1,1,1,0],[0,1,0,1,0],[0,1,1,1,0],[0,0,0,0,0]],
  "player_start": [1,1],
  "exit": [3,3],
  "enemies": [{"id":"e1","position":[2,2],"hp":20,"attack":5}],
  "items": []
}

IMPORTANT: Use ColoredRect (Paint filled rectangles) for all visuals. No image assets.
```

**Expected Output:** Game renders. Player can move. Enemy exists. Can win/lose.
**Manual Verification:** Play 5 turns manually. Verify combat math is correct.

---

### PHASE 4 — AI Agent System (Day 2, Morning, ~5 hours)
**Objectives:** All 5 agents implemented, connected to real Gemini API, returning valid JSON

Tasks:
- [ ] Base agent class with Gemini client + tracing
- [ ] LevelGeneratorAgent (most critical — generates real levels)
- [ ] DungeonMasterAgent (analyzes player, sets difficulty)
- [ ] RivalAgent (basic NPC decisions)
- [ ] NarrativeAgent (story text)
- [ ] RefereeAgent (action validation)
- [ ] Trace logger writing to Firestore
- [ ] Replace all mock routes with real agent calls

**Antigravity Prompt (Base + Level Generator):**
```
Read docs/AI_BEHAVIOR_SPECS.md, docs/PROMPT_SPECS.md, and docs/JSON_SCHEMAS.md.

Task: Implement the AI agent system for DungeonMind.

STEP 1 — Create mobile-game-server/agents/base_agent.py:
- BaseAgent class with:
  - gemini_client (google.generativeai)
  - model: "gemini-2.5-flash" 
  - trace_log: list of TraceEntry dicts
  - method: log_trace(step, reasoning, tool_called, tool_input, tool_output, decision)
  - method: run(context: dict) → abstract
  - method: get_traces() → list

STEP 2 — Create mobile-game-server/agents/level_generator.py:
- LevelGeneratorAgent(BaseAgent)
- run(context) receives: {difficulty: int, theme: str, player_class: str}
- System prompt: [use exact prompt from docs/PROMPT_SPECS.md - Level Generator section]
- Output: LevelSchema JSON (exact schema from docs/JSON_SCHEMAS.md)
- MUST use response_mime_type="application/json" to force JSON output
- Validate output against LevelSchema Pydantic model before returning
- If validation fails: retry once with stricter prompt, then return fallback level
- Log every step to trace

STEP 3 — Connect to /agent/generate-level route in routers/agents.py
- Replace mock response with real LevelGeneratorAgent().run(context)
- Save trace to Firestore at traces/{session_id}
```

**Manual Verification:** Call `/agent/generate-level` with test payload. Verify JSON is valid.
Check Firestore for trace entry.

---

### PHASE 5 — Full Integration (Day 2, Afternoon, ~4 hours)
**Objectives:** Flutter calls real AI agents, game renders AI-generated levels

Tasks:
- [ ] Flutter AgentService calls real backend (not mock)
- [ ] Session start → DungeonMaster called → plan returned → Level generated
- [ ] Flame renders AI-generated level JSON
- [ ] Enemy uses RivalAgent for decisions
- [ ] Narrative text appears in UI
- [ ] Post-game screen with score + trace preview
- [ ] Trace viewer screen

**Antigravity Prompt:**
```
Read docs/ARCHITECTURE.md and docs/UI_SPECS.md.

Task: Complete the integration between Flutter frontend and AI backend.

In lib/services/agent_service.dart:
- startSession(playerId, playerClass) → calls POST /agent/dungeon-master
- generateLevel(sessionId, difficulty, theme) → calls POST /agent/generate-level  
- getNPCDecision(sessionId, boardState) → calls POST /agent/npc-decision
- validateAction(sessionId, action) → calls POST /agent/validate-action
- getTraces(sessionId) → calls GET /traces/{sessionId}

In lib/features/game/game_screen.dart:
- On init: call startSession(), then generateLevel()
- Show "AI is preparing your dungeon..." loading overlay during calls
- Parse returned level JSON → pass to DungeonGame for rendering
- Every enemy turn: call getNPCDecision() → animate enemy based on response

In lib/features/game/widgets/ai_decision_panel.dart:
- Sliding bottom panel (drag up to expand)
- Shows last 5 AI decisions from trace
- Each entry: agent name (icon), reasoning text, timestamp
- Updates live via polling every 5 seconds

Create lib/features/traces/trace_viewer_screen.dart:
- List all trace entries for a session
- Each entry is an expandable card showing full trace JSON
- Formatted beautifully: agent name (colored), reasoning, decision
- "Share" button (screenshot)
```

**Manual Verification:** Full game run from login → play → see AI trace. End-to-end works.

---

### PHASE 6 — Polish + Demo Prep (Day 2, Evening, ~3 hours)
**Objectives:** Demo-ready product, all bugs fixed, demo scripted

Tasks:
- [ ] Fix all crashes from integration testing
- [ ] Add loading states and error messages
- [ ] Leaderboard screen
- [ ] Post-game AI feedback message (NarrativeAgent)
- [ ] App icon + name
- [ ] Demo account with pre-seeded loss history (AI adapts visibly)
- [ ] Export all Antigravity artifacts
- [ ] Write README.md
- [ ] Record demo video

---

## SECTION 5 — ANTIGRAVITY PROMPT ENGINEERING

### The Golden Rule of Prompting Antigravity

**BAD prompt:** "Build the game"
**GOOD prompt:** "Read [file]. Create [specific file] that does [specific thing] with [specific inputs/outputs]."

Antigravity performs best when it has:
1. A reference document to read first (always give it context)
2. A specific list of files to create or modify
3. The exact behavior to implement
4. Constraints (what NOT to do)

### Architecture Prompts

**When to use:** Start of project, restructuring, designing new modules
**How detailed:** Very detailed — paste your architecture doc

```
MASTER ARCHITECTURE PROMPT:

Read the following architecture overview carefully before doing anything:
[paste docs/ARCHITECTURE.md content]

Given this architecture, create the complete folder structure for both:
1. mobile-game/lib/ — Flutter app
2. mobile-game-server/ — FastAPI backend

Create placeholder files (no implementation yet) with correct imports and class stubs.
Add a comment at the top of each file explaining what it will contain.
Follow the exact naming conventions specified in the architecture.
```

### Flutter / Flame Prompts

**When to use:** Building any Flutter screen or Flame component
**How detailed:** Include screen name, components needed, data it displays

```
FLUTTER SCREEN PROMPT TEMPLATE:

Context: [paste relevant section of UI_SPECS.md]
Architecture: [paste Flutter layer from ARCHITECTURE.md]

Task: Create [ScreenName] at lib/features/[feature]/[screen_name].dart

This screen should:
- [List exactly what it displays]
- [List exactly what user can do]
- [List what data it reads from (provider/service)]
- [List what it navigates to on each action]

The screen receives these parameters: [list params]
It reads from these providers: [list providers]
It calls these service methods: [list service calls]

Use Material 3 widgets. Dark theme. Fantasy aesthetic.
Do NOT use any external image assets.
```

```
FLAME COMPONENT PROMPT TEMPLATE:

Context: [paste gameplay loop section]
JSON Schema: [paste level JSON schema]

Task: Create a Flame component at lib/features/game/flame/components/[name].dart

This component represents: [describe game entity]
It should:
- Render as: [describe visuals — colored rectangles only]
- Accept these properties: [list properties]
- React to: [list events/inputs]
- Emit: [list what it notifies the game of]

Performance constraint: Must render at 60fps on mid-range Android device.
Do not use any file assets (images, audio). Pure code rendering only.
```

### FastAPI Backend Prompts

```
FASTAPI ROUTE PROMPT TEMPLATE:

Context: [paste relevant API contract from API_CONTRACTS.md]
Models: [paste relevant Pydantic models]

Task: Implement the route [METHOD] /[path] in mobile-game-server/routers/[router].py

Request body: [paste request schema]
Response body: [paste response schema]
Logic:
1. [step 1]
2. [step 2]
3. [step 3]

Error handling:
- 400 if [condition]
- 500 if agent fails → return fallback response (never propagate 500 to client)

Use async/await. Add comprehensive logging. Add docstring.
```

### Gemini Integration Prompts

```
AGENT IMPLEMENTATION PROMPT TEMPLATE:

Read docs/AI_BEHAVIOR_SPECS.md section: [Agent Name]
Read docs/PROMPT_SPECS.md section: [Agent Name]
Read docs/JSON_SCHEMAS.md section: [Output schema name]

Task: Implement [AgentName] at mobile-game-server/agents/[agent_name].py

This agent:
- Goal: [one sentence goal]
- Input: [input dict structure]
- Output: [output dict structure — exact JSON schema name]
- System prompt: [paste exact prompt from PROMPT_SPECS.md]

CRITICAL REQUIREMENTS:
1. Use generation_config={"response_mime_type": "application/json"} ALWAYS
2. Validate output against [SchemaName] Pydantic model
3. On validation failure: retry once, then return FALLBACK_[SCHEMA_NAME]
4. Log every reasoning step via self.log_trace(...)
5. Cache output to Redis with key: [agent_name]:{hash_of_input}

Inherit from BaseAgent. Override run(context: dict) method only.
```

### Debugging Prompts

```
DEBUG PROMPT TEMPLATE:

Error:
[paste exact error + stack trace]

File: [paste the file contents where error occurs]

Context: This error happens when [describe what you did].

Task: 
1. Explain WHY this error is occurring
2. Fix it
3. Explain what you changed and why

Do NOT change any other behavior. Minimal targeted fix only.
```

### Refactoring Prompts

```
REFACTOR PROMPT TEMPLATE:

Reference pattern: [paste a well-written file as example]

File to refactor: [paste file]

Task: Refactor this file to:
- Follow the same patterns as the reference
- Improve readability
- Add missing docstrings
- Fix any inconsistent naming
- Do NOT change any external behavior or interfaces

Show me a summary of what you changed.
```

### UI Polishing Prompts

```
UI POLISH PROMPT TEMPLATE:

Current screen: [paste current implementation]
Design spec: [paste relevant UI_SPECS.md section]

Task: Polish this screen:
1. Add loading state (CircularProgressIndicator while awaiting data)
2. Add empty state (show message if no data)
3. Add error state (show retry button on error)
4. Ensure all text is readable on dark background
5. Add smooth transitions between states (AnimatedSwitcher)
6. Verify all tap targets are minimum 48x48dp

Do NOT change layout structure. Polish existing components only.
```

### Reusable Master Prompts

**CONTEXT INJECTION PROMPT (use at start of every session):**
```
I am building DungeonMind — an AI-powered roguelike dungeon crawler.
Stack: Flutter + Flame (mobile), FastAPI + Python (backend), Firebase (database), Gemini API (AI).
Architecture document: [paste ARCHITECTURE.md]
Current session goal: [describe specific goal]
Do not invent new patterns. Follow the existing architecture strictly.
```

**SCHEMA VALIDATION PROMPT:**
```
For any JSON output from AI agents:
1. Define the output as a Pydantic model first
2. Use response_mime_type="application/json" in Gemini call
3. Parse response with model.model_validate_json(response.text)
4. If validation fails, log the error and return the fallback object
5. Never let a validation error propagate to the Flutter client

Implement this pattern for: [agent name]
```

---

## SECTION 6 — FRONTEND DEVELOPMENT PLAN

### Flutter Architecture (Feature-First)

```
lib/
├── main.dart                    # App entry, Firebase init, ProviderScope
├── app/
│   ├── router.dart              # GoRouter configuration
│   └── theme.dart               # DungeonMind dark theme
├── features/
│   ├── auth/                    # Login screen + auth state
│   ├── menu/                    # Main menu
│   ├── character_select/        # 3-class selection
│   ├── game/                    # The game itself
│   │   ├── game_screen.dart     # Flutter wrapper around Flame
│   │   ├── game_provider.dart   # Riverpod game state
│   │   ├── widgets/
│   │   │   ├── ai_decision_panel.dart   # THE KEY FEATURE
│   │   │   ├── loading_overlay.dart
│   │   │   └── post_game_sheet.dart
│   │   └── flame/               # Flame components
│   │       ├── dungeon_game.dart
│   │       └── components/
├── features/traces/             # Trace viewer screen
├── features/leaderboard/        # Leaderboard screen
└── services/
    ├── agent_service.dart       # Calls backend AI routes
    ├── firebase_service.dart    # Firestore CRUD
    └── session_service.dart     # Manages active game session
```

### State Management (Riverpod)

```dart
// Core providers
authProvider          → AsyncValue<User?>
playerProvider        → AsyncValue<PlayerModel>
sessionProvider       → AsyncValue<SessionModel>
gameStateProvider     → StateNotifier<GameState>
traceProvider         → StateNotifier<List<TraceEntry>>

// GameState holds:
// - current level JSON
// - player position, hp, inventory
// - enemy states
// - turn number
// - last AI decision
// - session ID
```

### Screen Structure

| Screen | Route | Key Features |
|--------|-------|--------------|
| AuthScreen | /auth | Google login, anonymous login |
| MainMenuScreen | /menu | Player stats, 3 buttons, last run preview |
| CharacterSelectScreen | /character-select | 3 class cards, class stats |
| GameScreen | /game | Flame canvas + Flutter HUD + AI panel |
| TraceViewerScreen | /traces/:id | Formatted trace log, shareable |
| LeaderboardScreen | /leaderboard | Top 20 scores |
| PostGameScreen | /result | Score, AI feedback, trace preview |

### The AI Decision Panel (Most Important Widget)

```dart
// Located: lib/features/game/widgets/ai_decision_panel.dart
// Behavior:
// - Sits at bottom of game screen (collapsed by default: 60px tall)
// - Shows latest AI decision summary when collapsed
// - Drag up to expand: shows last 10 trace entries
// - Each entry has colored icon (which agent), reasoning text, timestamp
// - Auto-updates when new trace entry arrives (poll every 5s or WebSocket)
// - Pulsing "🧠 AI THINKING..." indicator when an agent call is in progress

// Design: Dark translucent background, gold text accents
// This widget is what judges will notice first in the demo
```

### Which Parts Antigravity Generates

- ALL screen scaffolding (let it write the boilerplate)
- ALL Riverpod provider boilerplate
- ALL Firebase CRUD operations
- GoRouter configuration
- HTTP client calls in AgentService

### Which Parts to Verify Manually

- Flame component hit-testing logic (subtle bugs here)
- State update order (race conditions possible)
- Navigation after auth state changes
- Error states on API failures

---

## SECTION 7 — BACKEND DEVELOPMENT PLAN

### FastAPI Structure

```
mobile-game-server/
├── main.py              # App factory, CORS, middleware, router mount
├── config.py            # Settings (env vars), Firebase init, Redis client, Gemini client
├── routers/
│   ├── agents.py        # POST /agent/* routes
│   ├── traces.py        # GET /traces/*
│   ├── players.py       # GET/POST /players/*
│   └── health.py        # GET /health
├── agents/
│   ├── base_agent.py    # BaseAgent ABC
│   ├── dungeon_master.py
│   ├── level_generator.py
│   ├── rival_agent.py
│   ├── narrative_agent.py
│   └── referee_agent.py
├── tools/
│   ├── player_tools.py  # DB reads for player history
│   ├── game_tools.py    # Level generation helpers
│   └── trace_tools.py   # Trace writing
├── models/
│   ├── requests.py      # All request Pydantic models
│   ├── responses.py     # All response Pydantic models
│   ├── level.py         # LevelSchema
│   ├── trace.py         # TraceEntry, TraceLog
│   └── session.py       # SessionModel
├── services/
│   ├── firebase_service.py   # Firestore CRUD
│   ├── redis_service.py      # Cache operations
│   └── session_service.py    # Session state management
└── fallbacks/
    ├── fallback_levels.py    # 3 hardcoded levels per theme
    └── fallback_responses.py # Safe defaults when AI fails
```

### Build Order: Mock → Hardcoded → AI-Powered

**Phase 1 (Mock):** All routes return `{"status": "ok", "data": {}}`
**Phase 2 (Hardcoded):** Routes return real-shaped data from `fallbacks/`
**Phase 3 (AI-Powered):** Routes call real agents, fallback to hardcoded if AI fails

This means the game is ALWAYS playable, even if Gemini is down.

### Redis Usage

```python
# Keys used:
f"session:{session_id}:dm_plan"      → DM session plan (TTL 3600s)
f"session:{session_id}:player_tactics" → NPC memory (TTL 3600s)
f"level:{hash(params)}"              → Cached level JSON (TTL 86400s)
f"rate:{player_id}:agent_calls"      → Rate limit counter (TTL 60s)

# Always try Redis first, then generate/compute, then cache result
```

### Firebase Admin SDK Integration

```python
# config.py initializes:
import firebase_admin
from firebase_admin import credentials, firestore, db as rtdb

app = firebase_admin.initialize_app(
    credentials.Certificate("serviceAccountKey.json"),
    {"databaseURL": "https://dungeonmind-default-rtdb.firebaseio.com"}
)
fs = firestore.client()    # Firestore
rt = rtdb.reference("/")   # Realtime DB (for live game state)
```

---

## SECTION 8 — AI SYSTEM DEVELOPMENT PLAN

### Implementation Order

Build in this exact order (each depends on the previous):

```
1. BaseAgent + TraceLogger (foundation everything uses)
2. LevelGeneratorAgent (most critical — game can't start without it)
3. RefereeAgent (needed for combat validation)
4. DungeonMasterAgent (session personalization)
5. RivalAgent (NPC intelligence)
6. NarrativeAgent (text generation — lowest priority)
```

### Minimal Version First Strategy

Each agent has 3 implementation levels:

```
LEVEL 1 (Day 1 — Get it working):
  LevelGeneratorAgent: generates valid 10x10 grid with enemies
  Returns: basic LevelSchema JSON
  
LEVEL 2 (Day 2 morning — Make it smart):
  Themes, difficulty params, item placement, balance validation
  
LEVEL 3 (Day 2 afternoon — Make it memorable):
  Player history influence, adaptive theme selection, narrative hooks
```

### JSON Schema Enforcement (Critical)

```python
# ALWAYS use this pattern for every Gemini call:
response = model.generate_content(
    prompt,
    generation_config=genai.GenerationConfig(
        response_mime_type="application/json",
        response_schema=YourPydanticModel.model_json_schema()
    )
)

try:
    result = YourPydanticModel.model_validate_json(response.text)
    return result
except ValidationError as e:
    self.log_trace("validation_failed", str(e), "retry_agent", {}, {}, "retrying")
    # Retry once with stricter prompt
    retry_response = model.generate_content(
        f"{prompt}\n\nCRITICAL: Your previous response had validation errors: {e}\n"
        f"You MUST output valid JSON matching this schema: {YourPydanticModel.model_json_schema()}"
    )
    try:
        return YourPydanticModel.model_validate_json(retry_response.text)
    except:
        return FALLBACK_LEVEL  # Never fail the user
```

### Latency Optimization

- Use `gemini-2.5-flash` for all real-time calls (fastest)
- Pre-generate next level in background while player plays current floor
- Cache levels by hash(difficulty_params + theme) — reuse if same params
- Timeout: 8 seconds max per agent call. If exceeded, return cached/fallback.

### How to Test AI Systems Safely

```python
# Create test_agents.py:
# Test each agent with 10 different inputs
# Verify output is always valid JSON
# Measure response time
# Check trace log is populated

async def test_level_generator():
    for difficulty in [1, 3, 5, 7, 10]:
        for theme in ["cursed_library", "volcanic_caves", "enchanted_forest"]:
            result = await LevelGeneratorAgent().run({
                "difficulty": difficulty, 
                "theme": theme,
                "player_class": "warrior"
            })
            assert LevelSchema.model_validate(result)
            assert len(result["enemies"]) > 0
            assert result["exit"] is not None
            print(f"✅ {theme} difficulty={difficulty}: valid")
```

---

## SECTION 9 — WHAT TO BUILD MANUALLY VS WITH ANTIGRAVITY

| System | Antigravity Generated | Manual Work Required | Risk Level |
|--------|----------------------|---------------------|-----------|
| Flutter screens (all) | 90% — Antigravity writes boilerplate | Review navigation, verify data flow | LOW |
| Flame tile renderer | 70% — basic setup | Manually tune tile sizes, test on device | MEDIUM |
| Flame combat logic | 50% — logic structure | Manually verify math, test edge cases | HIGH |
| Firebase Auth | 95% — standard code | Verify Google Sign-In on real device | LOW |
| Firestore CRUD | 95% — standard patterns | Verify reads/writes in console | LOW |
| AI agent classes | 60% — class structure | YOU write the system prompts manually | HIGH |
| Gemini API calls | 80% — boilerplate | YOU design the prompt, verify output | HIGH |
| Pydantic schemas | 95% — schema writing | Review field names match frontend | LOW |
| API routes | 90% — FastAPI boilerplate | Verify request/response shapes | LOW |
| Redis caching | 85% — standard patterns | Verify TTL values, test cache hit | MEDIUM |
| JSON schema design | 20% — YOU design this | This is architecture — your job | HIGH |
| Gemini prompts | 10% — Antigravity assists | YOU write + iterate prompts manually | CRITICAL |
| AI trace format | 30% — structure only | YOU decide what to log and why | HIGH |
| Demo script | 0% — entirely manual | YOU write and practice this | CRITICAL |
| Debugging | 80% — Antigravity fixes | YOU identify WHICH bug to fix | MEDIUM |
| Game balance | 0% — human judgment | YOU decide difficulty feels right | HIGH |

---

## SECTION 10 — DAILY EXECUTION PLAN

### Day 0 (3 hours — Documentation)
- Hours 1-2: Write all docs/ files (use provided templates)
- Hour 3: Setup dependencies, verify project runs, commit

**Checkpoint:** `flutter run` shows blank app. `uvicorn main:app` starts. Docs exist.

### Day 1 (12 hours — Foundation)
- Hours 1-4: Backend scaffold (Phase 1)
- Hours 4-8: Flutter scaffold (Phase 2)  
- Hours 8-12: Flame game engine (Phase 3)

**Checkpoint:** Game renders hardcoded level. Player can move. Combat works. No AI yet.

**CRITICAL:** If Flame is taking too long, use a SIMPLER renderer.
Fallback: render the dungeon as a Flutter GridView (colored Container widgets).
This is ugly but WORKS. AI depth beats pretty graphics every time.

### Day 2 (12 hours — AI + Integration + Polish)
- Hours 1-5: AI agent system (Phase 4)
- Hours 5-9: Full integration (Phase 5)
- Hours 9-11: Polish + bugfixes (Phase 6)
- Hours 11-12: Demo recording

**Checkpoint:** AI-generated level renders. Trace visible in app. Demo works twice consecutively.

### How to Checkpoint Progress

At the end of each 2-hour block:
```
[ ] App still runs (no regression)
[ ] New feature works on device
[ ] Code committed to git
[ ] No unreviewed Antigravity code in production files
```

### How to Prevent AI-Generated Spaghetti Code

1. **One file per agent session.** Don't let Antigravity touch 5 files at once.
2. **Review before running.** Read the diff before `flutter run`.
3. **Name things consistently.** If Antigravity uses different naming, refactor immediately.
4. **Keep agent code in `agents/`.** Don't let it bleed into routes or models.

---

## SECTION 11 — ANTIGRAVITY BEST PRACTICES

### Keep Context Clean

- Start new Antigravity conversation for each major module
- Never paste the entire codebase into one conversation
- Give agents only what they need: the relevant files + the relevant spec doc

### Avoid Conflicting Generations

- Track which files each agent "owns" mentally
- Never run two agents on the same file simultaneously
- If you change a shared model (e.g., LevelSchema), manually update ALL files that use it

### How to Review Generated Code (15-Minute Review Process)

```
For each generated file:
1. Check imports — are they all real packages we have?
2. Check class names — do they match our naming conventions?
3. Check method signatures — do inputs/outputs match our contracts?
4. Check error handling — does it have try/catch?
5. Check logging — does it log enough to debug?
6. Run it — does it at least not crash on startup?
```

### How to Ask for Refactors

```
"This code works but [specific problem]. 
Refactor it to [specific improvement].
Do NOT change [what must stay the same].
Show me the diff of what changed."
```

### How to Manage Large Files

If a file gets >300 lines:
1. Ask Antigravity to split it: "Extract [part] into a separate file [filename]"
2. Keep files under 200 lines as a rule
3. Flame components can be larger — that's normal

### Using Artifacts/Traces Effectively

Export Antigravity artifacts after:
1. Initial architecture session (shows system design planning)
2. Agent system implementation (shows AI engineering depth)
3. Any major refactor session (shows quality improvement process)

These go in `docs/ANTIGRAVITY_TRACES/` and are part of your submission.

---

## SECTION 12 — MVP STRATEGY FOR SOLO DEVELOPER

### The Smallest Possible MVP That Wins

```
MVP = 3 features working perfectly:
1. AI generates a playable dungeon level (visible, testable)
2. AI traces visible in-app (the judge's favorite thing)
3. Difficulty adapts based on player history (demonstrable in 60 seconds)

That's it. Everything else is secondary.
```

### Features to Completely Avoid

- Multiplayer (networking complexity kills hackathons)
- Sound and music (takes time, 0% of scoring)
- Sprite/pixel art (use colored rectangles, 0% of scoring)
- More than 3 level themes
- More than 3 character classes
- Save game / resume mechanic
- Tutorial / onboarding flow
- Settings screen
- Achievements system
- In-app purchases

### What Should Be Mocked / Faked

| Thing | Mock Version | Why Acceptable |
|-------|-------------|----------------|
| Provider discovery | JSON file | Judges allow this explicitly |
| User history (new account) | Pre-seeded demo account | Makes demo reliable |
| Next level pre-generation | Pre-generate before demo | Hides latency |
| Leaderboard data | Seeded fake entries | Judges don't verify |
| Player tactic analysis | First 3 sessions | NPC learning needs data |

### Where to Spend 80% of Effort

```
40% — AI Agent System (LevelGenerator + DungeonMaster + traces)
25% — AI Decision Panel (the visible proof of AI working)
20% — Core Game Loop (move, fight, win/lose — must be functional)
15% — Demo + Trace Viewer (packaging what you built)

NOT: Graphics, animations, sounds, extra screens
```

---

## SECTION 13 — FINAL EXECUTION STRATEGY

### Exact Build Order (If Starting Right Now)

```
Hour 1: Write all docs (ARCHITECTURE.md is most important)
Hour 2: FastAPI scaffold — all routes return mock JSON
Hour 3: Flutter scaffold — all screens navigate correctly
Hour 4: Flame renders hardcoded level (colored rectangles)
Hour 5: Player moves, combat works (basic)
Hour 6: BaseAgent + LevelGeneratorAgent (Level 1 — basic JSON output)
Hour 7: LevelGeneratorAgent (Level 2 — real themes + difficulty)
Hour 8: Connect Flutter → Backend → LevelGeneratorAgent → Flame (INTEGRATION)
Hour 9: DungeonMasterAgent (player history → difficulty params)
Hour 10: AI Decision Panel in UI (THE most important UI feature)
Hour 11: RivalAgent (basic NPC decisions)
Hour 12: TraceViewer screen + post-game screen
Hour 13: Polish, bug fixes, loading states
Hour 14: Seed demo account, test demo twice
Hour 15: Export Antigravity artifacts, write README
Hour 16: Record demo video
```

### Your First 10 Antigravity Prompts

```
Prompt 1: "Read docs/ARCHITECTURE.md. Create the complete folder structure 
  for both mobile-game and mobile-game-server with empty placeholder files."

Prompt 2: "Read docs/API_CONTRACTS.md and docs/JSON_SCHEMAS.md. 
  Scaffold the complete FastAPI backend with all routes returning mock JSON."

Prompt 3: "Read docs/UI_SPECS.md. Scaffold the Flutter app with all screens 
  and GoRouter navigation. Screens can be empty placeholder containers."

Prompt 4: "Read docs/GAMEPLAY_LOOP.md and docs/JSON_SCHEMAS.md. 
  Create the Flame DungeonGame with TileMapComponent that renders a 
  hardcoded 10x10 level using colored Paint rectangles."

Prompt 5: "Create PlayerComponent for Flame: blue 32x32 square, arrow key 
  movement, hp=100, attack=15. Create EnemyComponent: red square, hp=30, 
  attack=8, moves toward player after player's turn."

Prompt 6: "Read docs/AI_BEHAVIOR_SPECS.md. Create BaseAgent class and 
  LevelGeneratorAgent. Use Gemini API with JSON mode. Validate with LevelSchema."

Prompt 7: "Connect the /agent/generate-level route to LevelGeneratorAgent. 
  Replace mock response. Add trace logging to Firestore."

Prompt 8: "In Flutter, update AgentService to call the real backend. 
  In game_screen.dart, call generateLevel() on init and render returned JSON."

Prompt 9: "Create the AI Decision Panel widget. Shows last 5 trace entries. 
  Collapsible. Updates every 5 seconds by polling GET /traces/{session_id}."

Prompt 10: "Create DungeonMasterAgent that reads player history from Firestore 
  and returns difficulty parameters. Connect to game session start flow."
```

### Your First Coding Session (Hours 1-4)

```
00:00 — Open Antigravity with antigravity-game/ folder
00:10 — Paste Prompt 1 (folder structure). Review output.
00:30 — Add all dependencies to pubspec.yaml and pyproject.toml
00:50 — Paste Prompt 2 (FastAPI scaffold). Review output.
01:30 — Run uvicorn, verify /docs shows all routes
01:45 — Paste Prompt 3 (Flutter scaffold). Review output.
02:30 — Run flutter run, verify navigation works
02:50 — git commit -m "feat: complete project scaffold"
03:00 — Paste Prompt 4 (Flame tilemap). Review output.
03:40 — Run on device, verify grid renders
04:00 — [CHECKPOINT: backend runs, flutter runs, game grid visible]
```

### Architecture Freeze Point

**Freeze architecture after Hour 6** (once LevelGeneratorAgent works).

After this point: NO new modules, NO new screens, NO new agents.
Only: polish, connect, fix, demo.

If you add a new feature after hour 6, you risk breaking what works.

### Final Demo Focus

Your 3-minute demo must prove ONE thing:
**"The AI is making real decisions that visibly change what the player experiences."**

Show:
1. DM Agent log: player has 80% loss rate → difficulty reduced (30 seconds)
2. AI-generated level loads (different each time) (30 seconds)
3. Live AI Decision Panel during gameplay (60 seconds)
4. Enemy adapts to player tactics (30 seconds)
5. Trace viewer: "Here's every decision the AI made" (30 seconds)

Close with: *"Remove the AI agents, and this game stops working. The AI isn't a feature — it's the architecture."*

---

*DungeonMind | Built with Google Antigravity | Gemini 2.0 Flash | Flutter + Flame | FastAPI | Firebase*
