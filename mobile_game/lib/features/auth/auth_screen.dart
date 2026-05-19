import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../providers/auth_provider.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    ref.listen<AsyncValue>(
      authProvider,
      (_, state) {
        state.whenOrNull(
          error: (error, _) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.toString())),
            );
          },
        );
      },
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DungeonSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.local_fire_department,
                size: 64,
                color: DungeonColors.gold,
              ),
              const SizedBox(height: DungeonSpacing.md),
              Text(
                "DUNGEONMIND",
                style: DungeonText.displayLarge,
              ),
              const SizedBox(height: DungeonSpacing.sm),
              Text(
                "An AI-Powered Adventure",
                style: DungeonText.bodyMedium.copyWith(
                  color: DungeonColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: DungeonSpacing.xxl),
              if (authState.isLoading)
                const CircularProgressIndicator(color: DungeonColors.gold)
              else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text("SIGN IN WITH GOOGLE"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    ref.read(authProvider.notifier).signInWithGoogle();
                  },
                ),
                const SizedBox(height: DungeonSpacing.md),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DungeonColors.textSecondary,
                    side: const BorderSide(color: DungeonColors.textDim),
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  onPressed: () {
                    ref.read(authProvider.notifier).signInAnonymously();
                  },
                  child: const Text("PLAY ANONYMOUSLY"),
                ),
                const SizedBox(height: DungeonSpacing.lg),
                Text(
                  "Anonymous progress is\nnot saved between\nsessions.",
                  textAlign: TextAlign.center,
                  style: DungeonText.caption,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
