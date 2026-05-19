import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/error_card.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    ref.listen<AsyncValue>(authProvider, (_, state) {
      state.whenOrNull(
        error: (error, _) {
          ErrorCard.showSnackBarError(
            context,
            message: _friendlyAuthError(error),
            onRetry: () => ref.invalidate(authProvider),
          );
        },
      );
    });

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
              Text("DUNGEONMIND", style: DungeonText.displayLarge),
              const SizedBox(height: DungeonSpacing.sm),
              Text(
                "An AI-Powered Adventure",
                style: DungeonText.bodyMedium.copyWith(
                  color: DungeonColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: DungeonSpacing.xxl),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: authState.isLoading
                    ? const _LoadingIndicator(key: ValueKey('loading'))
                    : _AuthButtons(key: const ValueKey('buttons'), ref: ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _friendlyAuthError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('network') || msg.contains('socket')) {
      return "No internet connection. Please check your network and try again.";
    }
    if (msg.contains('cancel')) {
      return "Sign-in was cancelled.";
    }
    if (msg.contains('credential')) {
      return "Invalid credentials. Make sure you're using the correct account.";
    }
    return "Failed to sign in. Please try again.";
  }
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: DungeonColors.gold),
        const SizedBox(height: DungeonSpacing.md),
        Text(
          "Signing in…",
          style: DungeonText.caption.copyWith(color: DungeonColors.textDim),
        ),
      ],
    );
  }
}

class _AuthButtons extends StatelessWidget {
  final WidgetRef ref;

  const _AuthButtons({super.key, required this.ref});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: "Sign in with Google",
          child: ElevatedButton.icon(
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
              HapticFeedback.mediumImpact();
              ref.read(authProvider.notifier).signInWithGoogle();
            },
          ),
        ),
        const SizedBox(height: DungeonSpacing.md),
        Semantics(
          button: true,
          label: "Play anonymously without saving progress",
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: DungeonColors.textSecondary,
              side: const BorderSide(color: DungeonColors.textDim),
              minimumSize: const Size(double.infinity, 52),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(authProvider.notifier).signInAnonymously();
            },
            child: const Text("PLAY ANONYMOUSLY"),
          ),
        ),
        const SizedBox(height: DungeonSpacing.lg),
        Text(
          "Anonymous progress is\nnot saved between\nsessions.",
          textAlign: TextAlign.center,
          style: DungeonText.caption,
        ),
      ],
    );
  }
}
