# Repository Guides

## Project Structure & Module Organization

This repository contains a Flutter client, a FastAPI backend, and supporting design document.

- `mobile_game/` is the Flutter app. Source lives in `lib/`, feature screens in `lib/features/`, shared state in `lib/providers/`, models in `lib/models/`, and Flame gameplay code in `lib/features/game/flame/`.
- `mobile_game/test/` contains Flutter widget tests.
- `mobile-game-server/` is the Python backend. API routers are in `routers/`, AI agents in `agents/`, Pydantic schemas in `models/`, external integrations in `services/`, and fallback gameplay data in `fallbacks/`.
- `docs/` contains architecture, API contracts, schemas, gameplay loop, traces, and product specs.

## Build, Test, and Development Commands

Run Flutter commands from `mobile_game/`:

- `flutter pub get` installs Dart dependencies.
- `flutter run` launches the mobile app on the selected device or emulator.
- `flutter test` runs widget and unit tests.
- `flutter analyze` runs static analysis using `flutter_lints`.
- `dart format lib test` formats Dart code.

Run backend commands from `mobile-game-server/`:

- `uv sync` installs Python dependencies from `pyproject.toml` and `uv.lock`.
- `uv run uvicorn main:app --reload --host 0.0.0.0 --port 8000` starts the FastAPI server.

## Coding Style & Naming Conventions

Dart code follows `package:flutter_lints/flutter.yaml`; keep analyzer findings clean when touching a file. Use `dart format` before submitting changes. Prefer `UpperCamelCase` for widgets/classes, `lowerCamelCase` for methods and fields, and snake_case file names such as `game_screen.dart`.

Python backend code uses typed Pydantic models and async FastAPI handlers. Keep routers focused on HTTP concerns, put agent behavior in `agents/`, and shared integrations in `services/`.

## Testing Guidelines

Add Flutter tests under `mobile_game/test/` with names ending in `_test.dart`. Use `testWidgets` for UI behavior and keep tests deterministic; mock backend-dependent flows where possible. There is no dedicated backend test suite yet, so validate backend changes with focused manual route checks and add tests when introducing new agent or schema logic.

## Commit & Pull Request Guidelines

Recent commits use short imperative subjects such as `Fix traces endpoint` and `Fix the bottom overflow`. Keep commit titles concise and action-oriented.

Pull requests should include a brief summary, test results (`flutter test`, `flutter analyze`, backend route checks), linked issues when applicable, and screenshots or screen recordings for UI/gameplay changes.

## Security & Configuration Tips

Backend secrets live in `mobile-game-server/.env`; do not commit API keys or service account files. Use `BASELINE_MODE=true` in `.env` to disable AI calls and exercise fallback behavior during local development.
