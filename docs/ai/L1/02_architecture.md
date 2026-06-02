# 02 Architecture

> Runtime architecture for Flutter UI, backend control-plane calls, and Agora managed agent session.

## High-Level Shape

- Flutter app owns the visual shell and client session lifecycle.
- Backend companion owns privileged token generation and managed agent lifecycle calls.
- Browser or device joins Agora RTC and uses RTM for transcript, state, metrics, and error events.
- Agent executes STT -> LLM -> TTS in Agora cloud.

## Component Graph

```text
Flutter UI
  -> token endpoint
  -> invite endpoint
  -> RTC join/publish mic
  -> RTM subscribe + agent events
  -> stop endpoint

Backend companion
  -> token minting
  -> managed agent start/stop

Agora Cloud
  -> agent session
  -> RTM payloads
```

## Core State Domains

- App bootstrap and connection state.
- RTC transport and microphone lifecycle.
- Transcript, agent state, metrics, and connection issues.
- Environment and privileged credentials.

## Data and Control Boundaries

- The client never sees long-lived Agora secrets.
- Privileged lifecycle operations stay server-side.
- RTM carries data-plane events, not secrets.
- UI state changes should stay small and explicit.

