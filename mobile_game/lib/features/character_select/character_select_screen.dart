import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../providers/player_provider.dart';

enum PlayerClass { warrior, mage, ranger }

class CharacterSelectScreen extends ConsumerStatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  ConsumerState<CharacterSelectScreen> createState() =>
      _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends ConsumerState<CharacterSelectScreen> {
  PlayerClass? _selectedClass;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("CHOOSE YOUR CLASS", style: DungeonText.headingMedium),
      ),
      body: Padding(
        padding: const EdgeInsets.all(DungeonSpacing.md),
        child: Column(
          children: [
            Text(
              "Your Dungeon Master will adapt to your playstyle.",
              style: DungeonText.bodyMedium.copyWith(
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DungeonSpacing.xl),

            // Class Cards Row
            Row(
              children: [
                Expanded(
                  child: _ClassCard(
                    playerClass: PlayerClass.warrior,
                    isSelected: _selectedClass == PlayerClass.warrior,
                    onTap: () => _selectClass(PlayerClass.warrior),
                  ),
                ),
                const SizedBox(width: DungeonSpacing.sm),
                Expanded(
                  child: _ClassCard(
                    playerClass: PlayerClass.mage,
                    isSelected: _selectedClass == PlayerClass.mage,
                    onTap: () => _selectClass(PlayerClass.mage),
                  ),
                ),
                const SizedBox(width: DungeonSpacing.sm),
                Expanded(
                  child: _ClassCard(
                    playerClass: PlayerClass.ranger,
                    isSelected: _selectedClass == PlayerClass.ranger,
                    onTap: () => _selectClass(PlayerClass.ranger),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DungeonSpacing.xl),

            // Expanded info (animated)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SizeTransition(
                  sizeFactor: animation,
                  axisAlignment: -1.0,
                  child: child,
                ),
              ),
              child: _selectedClass != null
                  ? Container(
                      key: ValueKey(_selectedClass),
                      width: double.infinity,
                      padding: const EdgeInsets.all(DungeonSpacing.lg),
                      decoration: BoxDecoration(
                        color: DungeonColors.surfaceElevated,
                        borderRadius: const BorderRadius.all(DungeonRadius.md),
                        border: Border.all(color: DungeonColors.goldDim),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedClass
                                .toString()
                                .split('.')
                                .last
                                .toUpperCase(),
                            style: DungeonText.headingMedium.copyWith(
                              color: DungeonColors.gold,
                            ),
                          ),
                          const SizedBox(height: DungeonSpacing.sm),
                          Text(
                            _getClassDescription(_selectedClass!),
                            style: DungeonText.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),

            const Spacer(),

            // Enter button
            Semantics(
              button: true,
              enabled: _selectedClass != null,
              label: "Enter the dungeon",
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: DungeonColors.gold,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: DungeonColors.gold.withValues(
                    alpha: 0.3,
                  ),
                  disabledForegroundColor: Colors.black38,
                  minimumSize: const Size(double.infinity, 56),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(DungeonRadius.md),
                  ),
                ),
                onPressed: _selectedClass == null
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        final className = _selectedClass!.name.toLowerCase();
                        ref.read(playerProvider.notifier).setClass(className);
                        context.push('/game');
                      },
                child: Text(
                  "ENTER THE DUNGEON",
                  style: DungeonText.headingMedium.copyWith(
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: DungeonSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _selectClass(PlayerClass c) {
    HapticFeedback.selectionClick();
    setState(() => _selectedClass = c);
  }

  String _getClassDescription(PlayerClass c) {
    switch (c) {
      case PlayerClass.warrior:
        return "Melee attacks deal +50% damage. Best for beginners.";
      case PlayerClass.mage:
        return "Ranged spells bypass physical armor. Highly fragile.";
      case PlayerClass.ranger:
        return "High evasion and ranged attacks. Balanced survival.";
    }
  }
}

class _ClassCard extends StatelessWidget {
  final PlayerClass playerClass;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClassCard({
    required this.playerClass,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    int hp, atk, def;
    String desc;

    switch (playerClass) {
      case PlayerClass.warrior:
        icon = Icons.shield;
        hp = 150;
        atk = 20;
        def = 8;
        desc = "Strong melee";
      case PlayerClass.mage:
        icon = Icons.auto_fix_high;
        hp = 80;
        atk = 35;
        def = 3;
        desc = "Powerful ranged";
      case PlayerClass.ranger:
        icon = Icons.sports_handball;
        hp = 100;
        atk = 25;
        def = 5;
        desc = "Agile tactics";
    }

    return Semantics(
      button: true,
      label: "${playerClass.name} class: HP $hp, Attack $atk, Defense $def",
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: DungeonSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? DungeonColors.surfaceElevated
                : DungeonColors.surface,
            borderRadius: const BorderRadius.all(DungeonRadius.md),
            border: Border.all(
              color: isSelected ? DungeonColors.gold : DungeonColors.textDim,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: DungeonColors.gold.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                playerClass.toString().split('.').last.toUpperCase(),
                style: DungeonText.headingMedium.copyWith(
                  fontSize: 14,
                  color: isSelected
                      ? DungeonColors.gold
                      : DungeonColors.textPrimary,
                ),
              ),
              const SizedBox(height: DungeonSpacing.sm),
              Icon(
                icon,
                color: isSelected
                    ? DungeonColors.gold
                    : DungeonColors.textSecondary,
                size: 32,
              ),
              const SizedBox(height: DungeonSpacing.md),
              Text("HP: $hp", style: DungeonText.caption),
              Text("ATK: $atk", style: DungeonText.caption),
              Text("DEF: $def", style: DungeonText.caption),
              const SizedBox(height: DungeonSpacing.sm),
              Text(
                desc,
                style: DungeonText.caption.copyWith(
                  color: DungeonColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
