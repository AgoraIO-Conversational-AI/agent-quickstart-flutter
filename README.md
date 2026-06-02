# Agora Conversational AI Flutter Quickstart

Build a production-style voice agent in Flutter with the Agora Conversational AI Engine, including live transcript, agent state, and real-time call control.

## Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install)
- [Dart](https://dart.dev/get-dart)
- [Agora CLI](https://github.com/AgoraIO-Community/cli)
- An Agora project with Conversational AI enabled

## Run It

Getting started is straightforward: bind the app to an Agora project, install dependencies, and run the Flutter client.

1. **Install the Agora CLI and sign in**
   - skip this step if `agora` is already on your PATH

   ```bash
   curl -fsSL https://raw.githubusercontent.com/AgoraIO/cli/main/install.sh | sh -s -- --add-to-path
   agora login
   ```

2. **Bind the project and prepare local config**

   ```bash
   agora project use <your-project>
   agora project env write .env.local
   ```

3. **Install and run**

   ```bash
   flutter pub get
   flutter run -d chrome
   ```

4. Open the app in the target platform and continue with the session flow once the client and backend pieces land.

If the agent does not join or transcripts do not appear, run `agora project doctor --deep` to check credentials, feature enablement, network reachability, and local environment binding.

## Working from a clone of this repository

Use this path if you already cloned this repo and want to develop directly from it:

```bash
git clone <your-fork-or-local-repo-url>
cd agent-quickstart-flutter
agora login
agora project use <your-project>
agora project env write .env.local
agora project doctor --deep
flutter pub get
flutter run -d chrome
```

## Environment variables

Documented here once the backend control-plane lands.

| Variable | Required | Default | Notes |
| --- | ---: | ---: | --- |
| `AGORA_APP_ID` | ✅ | — | Agora Console project App ID. |
| `AGORA_APP_CERTIFICATE` | ✅ | — | Agora Console project App Certificate. Keep server-side only. |
| `AGENT_UID` |  | `123456` | Must match the managed agent uid used by the backend invite flow. |
| `AGENT_GREETING` |  | — | Optional override for the agent opening line. |

The default agent configuration will use Agora-managed STT, LLM, and TTS, so no extra vendor API keys are required for the base quickstart.

> **Default vs BYOK** - the quickstart will ship with Agora-managed inference first. Bring your own provider keys later only if you need custom model or vendor selection.

## Commands

```bash
# Dev
flutter run -d chrome     # run the Flutter app in Chrome

# Quality
flutter analyze           # static analysis
flutter test              # unit and widget tests

# Project setup
agora project doctor --deep
```

Run the narrowest relevant checks before you ship a change.

## Architecture

The Flutter client joins Agora RTC for audio transport and uses RTM for transcript, agent state, metrics, and error events. A backend companion will mint short-lived tokens and start or stop the managed agent session.

## What You Get

- Flutter voice client for web, iOS, and Android
- RTC audio plus RTM transcript and state events
- backend routes or services for token generation, invite, and stop
- live transcript, connection status, and call-state UI
- Agora-managed default STT, LLM, and TTS configuration

## How It Works

1. The client requests a short-lived token from the backend.
2. The backend invites the Agora managed agent for the selected channel.
3. The Flutter app joins the RTC channel and publishes microphone audio.
4. The client receives transcript, agent state, and metrics over RTM.
5. On end, the client calls the stop flow, logs out of RTM, and tears down the call view cleanly.

## Optional BYOK

The base quickstart will default to Agora-managed inference. If we add BYOK support later, the docs will list the provider-specific environment variables here.

## Repo Map

- `lib/main.dart` - Flutter app shell and entry point
- `docs/ai/` - progressive-disclosure docs for agents
- `AGENTS.md` - primary agent-facing guide
- `android/` - Android host app
- `ios/` - iOS host app

## Troubleshooting

- **Agent does not join or transcripts are missing:** run `agora project doctor --deep`.
- **Setup feels incomplete:** make sure the project is bound and local env values are written.
- **Voice or state flow is missing:** confirm the backend token and invite flow are implemented and the client subscribes to RTM.

## More Docs

- [docs/ai/L0_repo_card.md](./docs/ai/L0_repo_card.md)
- [docs/ai/RECIPE.md](./docs/ai/RECIPE.md)
- [AGENTS.md](./AGENTS.md)

## Security

Please do not open public issues for security reports. Use the appropriate Agora security contact path with details and reproduction steps.

