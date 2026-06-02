# 03 Code Map

> Directory-level ownership map and where to change behavior safely.

## Top-Level Layout

```text
lib/             Flutter app shell, widgets, models, and helpers
backend/          Companion server for privileged token and agent lifecycle work
docs/             Human-facing docs
docs/ai/          Progressive disclosure docs for agents
android/          Android host project
ios/              iOS host project
```

## Client Ownership (`lib/`)

- `main.dart`: app bootstrap and root navigation.
- Future feature folders: pre-call screen, call screen, transcript panel, metrics, and connection state.

## Backend Ownership (`backend/`)

- Token generation.
- Managed agent invite/start.
- Stop conversation.
- Optional health or contract checks.

## Validation and Tooling

- `flutter analyze` for static checks.
- `flutter test` for unit and widget tests.
- Backend validation will be documented with the companion service.

