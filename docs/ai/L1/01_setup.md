# 01 Setup

> Environment setup, commands, and safe verification flow for this quickstart.

## Runtime Requirements

- Flutter stable SDK.
- Dart SDK matching the Flutter channel.
- Agora project with Conversational AI enabled.
- A backend surface for token, invite, and stop operations.

## Install and Bootstrap

1. Install dependencies.
2. Bind the Agora project.
3. Write local environment values.
4. Verify setup before running.

## Primary Commands

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter run -d chrome`

Backend commands will be documented once the control-plane companion lands.

## Verification Safety

Safe without live session:

- `flutter analyze`
- `flutter test`

Requires env/project binding:

- end-to-end session checks

## Local Run Notes

- Start from the app shell and bootstrap the session in small steps.
- Keep token generation and agent invite outside the client runtime.
- If transcript or agent join fails, check the token, invite, and RTM wiring first.

