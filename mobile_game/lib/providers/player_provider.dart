import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

class PlayerModel {
  final String displayName;
  final String? playerClass;
  final int highScore;
  final int wins;
  final int losses;

  PlayerModel({
    required this.displayName,
    this.playerClass,
    this.highScore = 0,
    this.wins = 0,
    this.losses = 0,
  });

  PlayerModel copyWith({
    String? displayName,
    String? playerClass,
    int? highScore,
    int? wins,
    int? losses,
  }) {
    return PlayerModel(
      displayName: displayName ?? this.displayName,
      playerClass: playerClass ?? this.playerClass,
      highScore: highScore ?? this.highScore,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
    );
  }
}

class PlayerNotifier extends AsyncNotifier<PlayerModel> {
  @override
  Future<PlayerModel> build() async {
    final user = ref.watch(authProvider).value;

    if (user == null) {
      return PlayerModel(displayName: "Guest");
    }

    // In a real app, we would load from Firestore here using firebase_service
    // For now, return a placeholder model
    return PlayerModel(
      displayName: user.displayName ?? "Adventurer",
      highScore: 0,
      wins: 0,
      losses: 0,
    );
  }

  void setClass(String playerClass) {
    if (state.value != null) {
      state = AsyncValue.data(state.value!.copyWith(playerClass: playerClass));
    }
  }
}

final playerProvider = AsyncNotifierProvider<PlayerNotifier, PlayerModel>(() {
  return PlayerNotifier();
});
