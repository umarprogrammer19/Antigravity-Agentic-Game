# DungeonMind — UI Specifications
### Reference for: Flutter Architect Agent
---

## DESIGN SYSTEM

### Color Palette
```dart
// lib/app/theme.dart

class DungeonColors {
  // Primary Background
  static const background       = Color(0xFF0A0C12);   // Near-black, deep dungeon
  static const surface          = Color(0xFF13161F);   // Slightly lighter panels
  static const surfaceElevated  = Color(0xFF1C2030);   // Cards, modals

  // Accent Colors
  static const gold             = Color(0xFFD4AF37);   // Title text, highlights
  static const goldDim          = Color(0xFF8A7020);   // Secondary gold
  static const crimson          = Color(0xFFB91C1C);   // HP bar, danger
  static const crimsonLight     = Color(0xFFEF4444);   // HP text
  static const emerald          = Color(0xFF059669);   // Exit tile, success
  static const sapphire         = Color(0xFF2563EB);   // Player tile, info
  static const violet           = Color(0xFF7C3AED);   // Mage class, AI panel
  static const amber            = Color(0xFFF59E0B);   // XP, warnings

  // Text Colors
  static const textPrimary      = Color(0xFFE8E3D5);   // Main text (parchment)
  static const textSecondary    = Color(0xFF9CA3AF);   // Secondary text
  static const textDim          = Color(0xFF4B5563);   // Placeholder text

  // Agent Colors (for trace viewer)
  static const agentDM          = Color(0xFFD4AF37);   // Gold: Dungeon Master
  static const agentLevel       = Color(0xFF059669);   // Emerald: Level Generator
  static const agentRival       = Color(0xFFEF4444);   // Crimson: Rival NPC
  static const agentNarrative   = Color(0xFF7C3AED);   // Violet: Narrative
  static const agentReferee     = Color(0xFF2563EB);   // Sapphire: Referee

  // Game Tile Colors
  static const tileWall         = Color(0xFF1A1A2E);   // Dark blue-black
  static const tileFloor        = Color(0xFF2D1B0E);   // Dark brown
  static const tileLava         = Color(0xFFEA580C);   // Orange-red
  static const tileExit         = Color(0xFF047857);   // Dark emerald
  static const tileTrap         = Color(0xFF2D1B0E);   // Same as floor (hidden)
  static const tileTrapRevealed = Color(0xFF78350F);   // Dark amber (revealed)
}
```

### Typography
```dart
class DungeonText {
  // Display: Game title, floor headers
  static const displayLarge = TextStyle(
    fontFamily: 'Cinzel',     
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: DungeonColors.gold,
    letterSpacing: 2.0,
  );

  // Heading: Screen titles, section headers
  static const headingMedium = TextStyle(
    fontFamily: 'Cinzel',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: DungeonColors.textPrimary,
    letterSpacing: 1.0,
  );

  // Body: Normal text, descriptions
  static const bodyMedium = TextStyle(
    fontFamily: 'Crimson Text',  
    fontSize: 16,
    color: DungeonColors.textPrimary,
    height: 1.5,
  );

  // Caption: Small labels, metadata
  static const caption = TextStyle(
    fontFamily: 'Source Code Pro', 
    fontSize: 11,
    color: DungeonColors.textSecondary,
    letterSpacing: 0.5,
  );

  // Trace: Agent reasoning text
  static const trace = TextStyle(
    fontFamily: 'Source Code Pro',
    fontSize: 12,
    color: DungeonColors.textPrimary,
    height: 1.6,
  );
}
```

### Spacing & Sizing
```dart
class DungeonSpacing {
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 16.0;
  static const lg  = 24.0;
  static const xl  = 32.0;
  static const xxl = 48.0;
}

class DungeonRadius {
  static const sm = Radius.circular(6.0);
  static const md = Radius.circular(10.0);
  static const lg = Radius.circular(16.0);
  static const xl = Radius.circular(24.0);
}

// Minimum tap target: 48x48 dp (Material guideline)
```

---

## SCREEN 1: Auth Screen

**Route:** `/auth`
**Shown when:** User is not logged in OR first app launch

### Layout
```
┌─────────────────────────────────┐
│                                 │
│    [DUNGEONMIND LOGO]           │
│    ✦ Cinzel font, gold          │
│    "DUNGEONMIND"                │
│                                 │
│    [Subtitle]                   │
│    "An AI-Powered Adventure"    │
│    Crimson Text, dim            │
│                                 │
│    ─────────────────────        │
│                                 │
│    [SIGN IN WITH GOOGLE]        │
│    White button, Google icon    │
│    Full width - 16dp margins    │
│                                 │
│    [PLAY ANONYMOUSLY]           │
│    Dark outline button          │
│    Full width - 16dp margins    │
│                                 │
│    "Anonymous progress is       │
│     not saved between           │
│     sessions."                  │
│    Caption text, centered       │
│                                 │
│                                 │
└─────────────────────────────────┘
```

### Component Specs
```dart
// Logo section
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    // Flame/torch icon (use Icon widget — no image assets)
    Icon(Icons.local_fire_department, size: 64, color: DungeonColors.gold),
    SizedBox(height: 16),
    Text("DUNGEONMIND", style: DungeonText.displayLarge),
    SizedBox(height: 8),
    Text("An AI-Powered Adventure", style: DungeonText.bodyMedium.copyWith(
      color: DungeonColors.textSecondary,
      fontStyle: FontStyle.italic
    )),
  ]
)

// Google Sign In button
ElevatedButton.icon(
  icon: Icon(Icons.g_mobiledata, size: 24),  // G icon (no Google image asset)
  label: Text("SIGN IN WITH GOOGLE"),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    minimumSize: Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
)

// Anonymous button
OutlinedButton(
  child: Text("PLAY ANONYMOUSLY"),
  style: OutlinedButton.styleFrom(
    foregroundColor: DungeonColors.textSecondary,
    side: BorderSide(color: DungeonColors.textDim),
    minimumSize: Size(double.infinity, 52),
  ),
  onPressed: () => ref.read(authProvider.notifier).signInAnonymously(),
)
```

### States
```
INITIAL:    Buttons visible and enabled
LOADING:    CircularProgressIndicator replaces buttons
ERROR:      SnackBar with error message (buttons re-enabled)
SUCCESS:    Navigate to /character-select (first time) or /menu (returning)
```

---

## SCREEN 2: Main Menu Screen

**Route:** `/menu`
**Shown when:** User is authenticated

### Layout
```
┌─────────────────────────────────┐
│ [Back/Logout icon]   DUNGEONMIND│
├─────────────────────────────────┤
│                                 │
│  WARRIOR SALMAN                 │  ← Player name + class
│  ★ High Score: 4,820            │  ← Gold star icon
│  ──────────────────────         │
│  Wins: 12  │  Losses: 8         │
│                                 │
├─────────────────────────────────┤
│                                 │
│  ┌──────────────────────────┐   │
│  │  ⚔️  NEW RUN              │   │  ← Primary action, gold border
│  │  Your Dungeon Master     │   │
│  │  is ready...             │   │
│  └──────────────────────────┘   │
│                                 │
│  ┌─────────────┐ ┌────────────┐ │
│  │ 📜 LAST RUN │ │ 🏆 RANKS   │ │  ← Secondary actions
│  └─────────────┘ └────────────┘ │
│                                 │
│  ┌──────────────────────────┐   │
│  │  Last Run Summary        │   │
│  │  Floor 3 · 8 enemies     │   │  ← Collapsed card
│  │  Lost to Shadow Mage     │   │
│  │  [View AI Decisions →]   │   │
│  └──────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

### Component Specs
```dart
// Player stats card
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: DungeonColors.surfaceElevated,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: DungeonColors.goldDim.withOpacity(0.3)),
  ),
  child: Column(...)
)

// NEW RUN button — primary CTA
GestureDetector(
  onTap: () => context.push('/character-select'),
  child: Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1A0A00), Color(0xFF2D1500)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: DungeonColors.gold, width: 1.5),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.sword_rounded, color: DungeonColors.gold, size: 28),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("NEW RUN", style: DungeonText.headingMedium.copyWith(color: DungeonColors.gold)),
            Text("Your Dungeon Master is ready...", style: DungeonText.caption),
          ]
        )
      ]
    )
  )
)
```

---

## SCREEN 3: Character Select Screen

**Route:** `/character-select`

### Layout
```
┌─────────────────────────────────┐
│ [←]    CHOOSE YOUR CLASS        │
│                                 │
│  "Your Dungeon Master will      │
│   adapt to your playstyle."     │
│                                 │
│  ┌─────────┐ ┌────────┐ ┌────┐  │
│  │ WARRIOR │ │  MAGE  │ │ .. │  │
│  │   ⚔️    │ │   🔮   │ │    │  │
│  │         │ │        │ │    │  │
│  │HP: 150  │ │HP:  80 │ │    │  │
│  │ATK:  20 │ │ATK: 35 │ │    │  │
│  │DEF:   8 │ │DEF:  3 │ │    │  │
│  │         │ │        │ │    │  │
│  │ Strong  │ │Powerful│ │    │  │
│  │ melee   │ │ranged  │ │    │  │
│  └─────────┘ └────────┘ └────┘  │
│                                 │
│  [Selected card has gold border]│
│                                 │
│  ┌──────────────────────────┐   │
│  │  WARRIOR                 │   │  ← Expanded info for selected
│  │  Melee attacks deal      │   │
│  │  +50% damage. Best for   │   │
│  │  beginners.              │   │
│  └──────────────────────────┘   │
│                                 │
│  [  ENTER THE DUNGEON  ]        │
│                                 │
└─────────────────────────────────┘
```

### Class Cards
```dart
// Each class card is a selectable widget
class ClassCard extends StatelessWidget {
  final PlayerClass playerClass;  // enum: warrior, mage, ranger
  final bool isSelected;
  final VoidCallback onTap;

  // Card content:
  // - Class name (Cinzel font, capitalized)
  // - Class icon (Icons.shield for warrior, Icons.auto_fix_high for mage, Icons.sports_handball for ranger)
  // - HP, ATK, DEF stats (3 rows)
  // - 1-line description

  // Selected state: gold border + slightly elevated background
  // Unselected state: dim border, dark background
}
```

---

## SCREEN 4: Game Screen

**Route:** `/game`
**This is the most complex screen**

### Layout
```
┌─────────────────────────────────┐
│ HP ████████░░ 85/150 │ Floor 2  │  ← HUD TOP
│                      │ Turn 14  │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐    │
│  │                         │    │
│  │   DUNGEON GRID          │    │
│  │   (Flame canvas)        │    │
│  │                         │    │
│  │   🟦 Player             │    │
│  │   🟥 Enemies            │    │
│  │   🟩 Exit tile          │    │
│  │   ⬛ Walls              │    │
│  │   🟫 Floor              │    │
│  │                         │    │
│  └─────────────────────────┘    │
│                                 │
│  D-pad or WASD controls:        │  ← Optional d-pad widget
│  ┌─────────────────────────┐    │
│  │    [↑]                  │    │
│  │ [←][•][→]               │    │
│  │    [↓]                  │    │
│  └─────────────────────────┘    │
│                                 │
├─────────────────────────────────┤
│ 🧠 Goblin flanked right—        │  ← AI PANEL (collapsed, 60px)
│    rush pattern detected        │
│                        [drag ↑] │
└─────────────────────────────────┘
```

### AI Decision Panel (Expanded)
```
┌─────────────────────────────────┐
│ AI DECISION LOG          [▼]    │
│ ─────────────────────────────── │
│                                 │
│ 🟡 DUNGEON MASTER · 10:32:01   │
│    "Player loss rate 80%.       │
│     Easy mode applied."         │
│    Decision: Difficulty → 3/10  │
│                                 │
│ 🟢 LEVEL GENERATOR · 10:32:04  │
│    "Generating 10×10 grid for   │
│     enchanted_forest, diff 3"   │
│    Decision: 2 enemies, 1 item  │
│                                 │
│ 🔴 RIVAL AGENT · 10:32:45      │
│    "Player moved right 4 times. │
│     Cutting off escape route."  │
│    Decision: Goblin flanks east │
│                                 │
│ 🔵 REFEREE · 10:32:46          │
│    "Player attacked Goblin.     │
│     20 atk - 3 def = 17 dmg"   │
│    Decision: 17 damage dealt    │
│                                 │
└─────────────────────────────────┘
```

### HUD Component Specs
```dart
// HP Bar
class HpBar extends StatelessWidget {
  final int currentHp;
  final int maxHp;

  // Shows:
  // - Red filled LinearProgressIndicator (hp/maxHp)
  // - Text: "85/150" in crimsonLight color
  // - Icon: Icons.favorite (heart)
  // Animate HP changes smoothly with AnimatedContainer
}

// Turn Phase Indicator
class TurnIndicator extends StatelessWidget {
  final String turnPhase;  // "YOUR TURN" | "ENEMY THINKING..." | "ANIMATING"

  // Color changes:
  // player_turn:  Gold text "YOUR TURN"
  // enemy_turn:   Red pulsing "ENEMY THINKING..."
  // animating:    Gray "..."
}
```

### AI Decision Panel Specs
```dart
// lib/features/game/widgets/ai_decision_panel.dart

class AiDecisionPanel extends ConsumerWidget {
  // Collapsed height: 60px
  // Expanded height: min(350px, 60% of screen height)
  // Drag handle at top (drag up to expand)
  // DraggableScrollableSheet widget

  // Each trace entry card:
  // - Left: colored dot (agent color) + agent name abbreviation
  // - Middle: reasoning text (2 lines max, truncated)
  // - Right: timestamp (HH:mm:ss)
  // - Bottom: decision text in gold

  // "AI THINKING..." animation:
  // When ai_is_thinking == true:
  //   Show pulsing dots animation
  //   Panel background becomes slightly brighter
  //   Text: "🧠 AI THINKING..."

  // Agent color mapping:
  Map<String, Color> agentColors = {
    'DungeonMasterAgent': DungeonColors.agentDM,
    'LevelGeneratorAgent': DungeonColors.agentLevel,
    'RivalAgent': DungeonColors.agentRival,
    'NarrativeAgent': DungeonColors.agentNarrative,
    'RefereeAgent': DungeonColors.agentReferee,
  };

  // Agent abbreviations for small icon:
  Map<String, String> agentAbbrev = {
    'DungeonMasterAgent': 'DM',
    'LevelGeneratorAgent': 'LG',
    'RivalAgent': 'NPC',
    'NarrativeAgent': 'NAR',
    'RefereeAgent': 'REF',
  };
}
```

### D-Pad Controls
```dart
// Virtual d-pad for touch devices
class DPad extends StatelessWidget {
  final Function(String direction) onDirectionTap;

  // Layout: 3x3 grid, center empty
  // Up: row 0 col 1
  // Left: row 1 col 0
  // Right: row 1 col 2
  // Down: row 2 col 1
  // Each button: 52x52dp, Icons.arrow_*
  // Also listen to keyboard events (WASD + arrow keys) for emulator testing
}
```

---

## SCREEN 5: Loading Overlay

**Used during:** Session start (DM agent), floor generation, floor transitions

```
┌─────────────────────────────────┐
│                                 │
│     ▓▓▓▓▓▓░░░░ 60%             │
│                                 │
│     🧠 Your Dungeon Master      │
│        is preparing your run... │
│                                 │
│     Step 2/3: Generating        │
│     your dungeon...             │
│                                 │
│     [animated flame icon]       │
│                                 │
└─────────────────────────────────┘
```

```dart
class LoadingOverlay extends StatelessWidget {
  final String message;
  final String subMessage;
  final double? progress;  // null = indeterminate

  // Full-screen semi-transparent overlay
  // Background: Colors.black87
  // Centered column: icon + progress bar + messages
  // Icon: rotating fire icon (RotationTransition)
  // Progress bar: LinearProgressIndicator (gold color)
  // Never show this for > 10 seconds — show error if exceeded
}
```

---

## SCREEN 6: Post-Game / Result Screen

**Route:** `/result`

### Win State
```
┌─────────────────────────────────┐
│                                 │
│    ✦ DUNGEON CLEARED ✦         │
│    Gold text, Cinzel font       │
│                                 │
│  ┌──────────────────────────┐   │
│  │  SCORE: 4,820            │   │
│  │  ────────────────────    │   │
│  │  Floors Cleared:    5/5  │   │
│  │  Enemies Killed:     18  │   │
│  │  Turns Taken:        72  │   │
│  │  Time:           7m 30s  │   │
│  └──────────────────────────┘   │
│                                 │
│  ┌──────────────────────────┐   │
│  │ 🧠 AI DUNGEON MASTER SAYS│   │
│  │ "Exceptional run. You    │   │
│  │  adapted to each floor.  │   │
│  │  Try the Volcanic Caves  │   │
│  │  for your next run."     │   │
│  └──────────────────────────┘   │
│                                 │
│  [VIEW AI DECISIONS]  [SHARE]   │
│  [      PLAY AGAIN      ]       │
│                                 │
└─────────────────────────────────┘
```

### Death State
```
┌─────────────────────────────────┐
│                                 │
│    💀 SLAIN ON FLOOR 3          │
│    Crimson text                 │
│    "By Shadow Mage"             │
│                                 │
│  ┌──────────────────────────┐   │
│  │  SCORE: 1,240            │   │
│  │  Floors Cleared:    2/5  │   │
│  │  Enemies Killed:      8  │   │
│  └──────────────────────────┘   │
│                                 │
│  ┌──────────────────────────┐   │
│  │ 🧠 YOUR DUNGEON MASTER   │   │
│  │    OBSERVED:             │   │
│  │                          │   │
│  │ "You engaged 3 enemies   │   │
│  │  simultaneously 4 times. │   │
│  │  Next time: isolate one  │   │
│  │  enemy before engaging." │   │
│  │                          │   │
│  │ "Difficulty has been     │   │
│  │  adjusted for your next  │   │
│  │  run."                   │   │
│  └──────────────────────────┘   │
│                                 │
│  [VIEW AI DECISIONS]            │
│  [      TRY AGAIN      ]        │
│                                 │
└─────────────────────────────────┘
```

---

## SCREEN 7: Trace Viewer Screen

**Route:** `/traces/:sessionId`
**This screen is for judges — make it beautiful**

### Layout
```
┌─────────────────────────────────┐
│ [←]   AI DECISION LOG          │
│        Session · 14 decisions   │
│                                 │
│  [DM] [LV] [NPC] [NAR] [REF]   │  ← Filter chips
│         All selected            │
│                                 │
│  ┌──────────────────────────┐   │
│  │ 🟡 DUNGEON MASTER        │   │
│  │ Step 1 of 4 · 10:32:01   │   │
│  │ ──────────────────────── │   │
│  │ Reasoning:               │   │
│  │ "Player has 80% loss     │   │
│  │  rate. Applying easy     │   │
│  │  mode for this session." │   │
│  │                          │   │
│  │ Tool: compute_stats      │   │
│  │ Input:  {wins:2,losses:8}│   │
│  │ Output: {rate:0.8,cat:   │   │
│  │          "struggling"}   │   │
│  │                          │   │
│  │ ✓ Decision:              │   │
│  │ "Difficulty → 3/10.      │   │
│  │  Enemy speed → 0.8x."    │   │
│  │                     12ms │   │
│  └──────────────────────────┘   │
│                                 │
│  [More trace cards below...]    │
│                                 │
│  [📤 EXPORT]  [📸 SCREENSHOT]   │
└─────────────────────────────────┘
```

### Trace Card Specs
```dart
class TraceEntryCard extends StatelessWidget {
  final TraceEntry trace;

  // Header: colored dot + agent name + "Step X" + timestamp
  // Divider line
  // "Reasoning" label + reasoning text (italic, parchment color)
  // "Tool Called" label + tool name (monospace, dim)
  // "Input" label + JSON preview (collapsible, monospace, small)
  // "Output" label + JSON preview (collapsible, monospace, small)
  // "Decision" label + decision text (gold, bold)
  // "Xms" — processing time (bottom right, dim)

  // All trace cards are expandable/collapsible
  // Default: show only reasoning + decision (collapsed)
  // Expanded: show full JSON input/output
}
```

---

## SCREEN 8: Leaderboard Screen

**Route:** `/leaderboard`

```
┌─────────────────────────────────┐
│ [←]    LEADERBOARD              │
│                                 │
│  ┌──────────────────────────┐   │
│  │ #1 DungeonMaster  4,820  │   │
│  │    Mage · 5 floors       │   │
│  ├──────────────────────────┤   │
│  │ #2 ShadowSlayer   3,640  │   │
│  │    Warrior · 5 floors    │   │
│  ├──────────────────────────┤   │
│  │ ...                      │   │
│  ├──────────────────────────┤   │
│  │ #15 ★ YOU        1,240   │   │  ← Current player highlighted
│  │    Warrior · 2 floors    │   │
│  └──────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

---

## NAVIGATION FLOW

```
App Start
    │
    ├─ Not logged in → /auth
    │       │
    │       ├─ Google sign in success → /character-select (first time)
    │       │                         → /menu (returning user)
    │       └─ Anonymous → /character-select
    │
    └─ Logged in → /menu
           │
           ├─ "NEW RUN" → /character-select
           │       │
           │       └─ Select class + tap "ENTER" → /game
           │               │
           │               ├─ Game over (win/loss) → /result
           │               │       │
           │               │       ├─ "VIEW AI DECISIONS" → /traces/:sessionId
           │               │       └─ "PLAY AGAIN" → /character-select
           │               │
           │               └─ Pause menu → back to /menu (abandon run)
           │
           ├─ "LAST RUN" → /traces/:lastSessionId
           └─ "RANKS" → /leaderboard
```

---

## FLUTTER IMPLEMENTATION NOTES

### Performance Rules for Flame
```dart
// NEVER call setState() from inside Flame components
// NEVER do Firebase/HTTP calls inside Flame render loop
// Use callbacks to notify Flutter: game.onEvent = (event) => ...
// Flame runs on its own game loop — keep it pure game logic only
```

### Loading States (Required for All Async Calls)
```dart
// Every screen with async data MUST have 3 states:
// 1. Loading: CircularProgressIndicator (gold color)
// 2. Data: Normal content
// 3. Error: Error message + retry button

// Use AsyncValue from Riverpod:
ref.watch(someProvider).when(
  data: (data) => ContentWidget(data),
  loading: () => LoadingWidget(),
  error: (error, _) => ErrorWidget(onRetry: () => ref.invalidate(someProvider)),
);
```

### Animation Guidelines
```dart
// Use these animations (no custom animation code needed):
AnimatedSwitcher   — For state transitions (loading → content)
AnimatedContainer  — For HP bar changes, panel expand/collapse
FadeTransition     — For screen transitions
SlideTransition    — For AI decision panel slide up

// Game tile animations (in Flame):
// Enemy death: opacity fade 0 over 500ms
// Damage number: translate up + opacity fade over 800ms
// Player movement: lerp position over 150ms (feels snappy)
// Item collect: scale up then fade over 400ms
```

---

*All screens should be dark by default. No white backgrounds.*
*All buttons minimum 48dp tap target.*
*All loading states show immediately (never let user stare at blank screen).*
*The AI Decision Panel is the most important UI feature — make it beautiful.*
