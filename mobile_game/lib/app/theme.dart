import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DungeonColors {
  // Primary Background
  static const background = Color(0xFF0A0C12);
  static const surface = Color(0xFF13161F);
  static const surfaceElevated = Color(0xFF1C2030);

  // Accent Colors
  static const gold = Color(0xFFD4AF37);
  static const goldDim = Color(0xFF8A7020);
  static const crimson = Color(0xFFB91C1C);
  static const crimsonLight = Color(0xFFEF4444);
  static const emerald = Color(0xFF059669);
  static const sapphire = Color(0xFF2563EB);
  static const violet = Color(0xFF7C3AED);
  static const amber = Color(0xFFF59E0B);

  // Text Colors
  static const textPrimary = Color(0xFFE8E3D5);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textDim = Color(0xFF4B5563);

  // Agent Colors
  static const agentDM = Color(0xFFD4AF37);
  static const agentLevel = Color(0xFF059669);
  static const agentRival = Color(0xFFEF4444);
  static const agentNarrative = Color(0xFF7C3AED);
  static const agentReferee = Color(0xFF2563EB);

  // Game Tile Colors
  static const tileWall = Color(0xFF1A1A2E);
  static const tileFloor = Color(0xFF2D1B0E);
  static const tileLava = Color(0xFFEA580C);
  static const tileExit = Color(0xFF047857);
  static const tileTrap = Color(0xFF2D1B0E);
  static const tileTrapRevealed = Color(0xFF78350F);
}

class DungeonText {
  static final TextStyle displayLarge = GoogleFonts.cinzel(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: DungeonColors.gold,
    letterSpacing: 2.0,
  );

  static final TextStyle headingMedium = GoogleFonts.cinzel(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: DungeonColors.textPrimary,
    letterSpacing: 1.0,
  );

  static final TextStyle bodyMedium = GoogleFonts.crimsonText(
    fontSize: 16,
    color: DungeonColors.textPrimary,
    height: 1.5,
  );

  static final TextStyle caption = GoogleFonts.sourceCodePro(
    fontSize: 11,
    color: DungeonColors.textSecondary,
    letterSpacing: 0.5,
  );

  static final TextStyle trace = GoogleFonts.sourceCodePro(
    fontSize: 12,
    color: DungeonColors.textPrimary,
    height: 1.6,
  );
}

class DungeonSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

class DungeonRadius {
  static const sm = Radius.circular(6.0);
  static const md = Radius.circular(10.0);
  static const lg = Radius.circular(16.0);
  static const xl = Radius.circular(24.0);
}

final dungeonTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: DungeonColors.background,
  colorScheme: const ColorScheme.dark(
    primary: DungeonColors.gold,
    secondary: DungeonColors.sapphire,
    surface: DungeonColors.surface,
    error: DungeonColors.crimson,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: DungeonColors.textPrimary,
    onError: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: DungeonColors.surface,
    foregroundColor: DungeonColors.textPrimary,
    elevation: 0,
    centerTitle: true,
  ),
  textTheme: TextTheme(
    displayLarge: DungeonText.displayLarge,
    headlineMedium: DungeonText.headingMedium,
    bodyMedium: DungeonText.bodyMedium,
    labelSmall: DungeonText.caption,
  ),
);
