# 06 Interfaces

> API contracts, event payloads, and environment contracts.

## Environment Contracts

- Document required Agora app values here once the backend companion lands.
- Keep server-only secrets out of the client runtime.

## Session Contracts

- Token endpoint: returns the short-lived credentials needed for the current channel.
- Invite endpoint: starts the managed agent session for the channel.
- Stop endpoint: ends the managed agent session and is safe to call repeatedly.

## Event Contracts

- Transcript updates.
- Agent state updates.
- Metric events.
- Error or connection events.

