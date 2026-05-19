import 'package:flutter_riverpod/legacy.dart';
import '../models/level_schema.dart';
import '../models/session_plan.dart';

enum SessionStatus { idle, starting, active, finished, error }

class SessionModel {
  final SessionStatus status;
  final SessionPlan? plan;
  final LevelSchema? currentLevel;

  SessionModel({
    this.status = SessionStatus.idle,
    this.plan,
    this.currentLevel,
  });

  SessionModel copyWith({
    SessionStatus? status,
    SessionPlan? plan,
    LevelSchema? currentLevel,
  }) {
    return SessionModel(
      status: status ?? this.status,
      plan: plan ?? this.plan,
      currentLevel: currentLevel ?? this.currentLevel,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionModel> {
  SessionNotifier() : super(SessionModel());

  void setStatus(SessionStatus status) {
    state = state.copyWith(status: status);
  }

  void setPlan(SessionPlan plan) {
    state = state.copyWith(plan: plan);
  }

  void setLevel(LevelSchema level) {
    state = state.copyWith(currentLevel: level);
  }

  void clear() {
    state = SessionModel();
  }
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionModel>((
  ref,
) {
  return SessionNotifier();
});
