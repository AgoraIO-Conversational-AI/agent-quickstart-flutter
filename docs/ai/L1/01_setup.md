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

The repo-root `.env.local` file is the single runtime config source for the backend companion. The Flutter client loads its public config from the backend companion at startup. The Flutter client uses `http://localhost:3001` by default on web and `http://10.0.2.2:3001` on Android emulator, and `BACKEND_BASE_URL` only when it needs to point away from the local backend default.

## Primary Commands

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `flutter run -d chrome`
- `cd backend && npm install`
- `cd backend && npm run dev`
- `flutter run -d chrome --dart-define=BACKEND_BASE_URL=http://localhost:3001`

## Verification Safety

Safe without live session:

- `flutter analyze`
- `flutter test`

Requires env/project binding:

- end-to-end session checks

## Local Run Notes

- Start from the app shell and bootstrap the session in small steps.
- Keep token generation and agent invite outside the client runtime.
- Run the Flutter app and backend companion in separate terminals during local development.
- If the session does not start, check the token, invite, RTC setup, microphone permission, and that the backend companion is running first.
