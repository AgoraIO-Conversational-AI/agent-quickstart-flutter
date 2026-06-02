---
recipe_version: 0.1.0
recipe_status: draft
extension_points:
  - app.bootstrap
  - backend.routes
  - prompts.system
  - pipeline.providers
  - ui.conversation
invariants:
  - baseline.official-sample
  - tokens.rtc-rtm
  - lifecycle.strict-mode-safe
  - transcript.uid-remap
stable_contracts:
  - env.required
  - api.token
  - api.invite-agent
  - api.stop-conversation
---

# Quickstart Recipe Profile

This repository is the Flutter migration baseline for the Agora Conversational AI quickstart.

## Recipe Role

- Role: `base` quickstart recipe.
- Target audience: developers bootstrapping a production-style Agora voice agent app in Flutter.
- Reuse model: clone, bind project, run, then customize prompt, pipeline, and UI.

## Recipe Scope

This base recipe should provide a copyable app with:

- Flutter client UI for pre-call and in-call states
- RTC audio transport and RTM event handling
- backend token, invite, and stop flows
- transcript, metrics, and connection-status UI
- a small documentation set that keeps future changes low-context

## Baseline Guidance

Use the repo source and progressive disclosure docs as the source of truth.

Do not rebuild Agora integration from memory. Verify provider schemas, token behavior, and event contracts against the current implementation before changing them.

## Extension Points

- `app.bootstrap`: client startup, pre-call state, and session transitions.
- `backend.routes`: token generation, invite, and stop endpoints or services.
- `prompts.system`: agent behavior and greeting text.
- `pipeline.providers`: STT, LLM, and TTS provider choices.
- `ui.conversation`: transcript, metrics, connection, and call controls.

## Invariants

- Keep RTM-capable tokens, not RTC-only tokens.
- Keep session startup and teardown isolated from the UI shell.
- Keep documentation synchronized when workflows or contracts change.
- Keep any custom skill or MCP server narrowly scoped to repeated work.

## Stable Contracts

- A token endpoint returns the short-lived channel/session credentials needed by the client.
- An invite endpoint starts the managed agent session.
- A stop endpoint ends the managed agent session and treats already-stopping cases as success.
- Required environment variables are documented in [01_setup](L1/01_setup.md).

## Consumer Onboarding Recipe

1. Clone or scaffold from template.
2. Bind the Agora project and write local env values.
3. Run the narrowest verification commands first.
4. Validate the end-to-end session before expanding the UI.
5. Customize agent behavior only after the baseline flow works.

