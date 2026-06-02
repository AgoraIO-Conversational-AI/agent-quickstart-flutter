# 06 Interfaces

> API contracts, event payloads, and environment contracts.

## Environment Contracts

- `NEXT_PUBLIC_AGORA_APP_ID`: Agora Console project App ID.
- `NEXT_AGORA_APP_CERTIFICATE`: Agora Console project App Certificate, server-side only.
- `NEXT_PUBLIC_AGENT_UID`: agent uid used by the invite flow.
- `NEXT_AGENT_GREETING`: optional override for the agent greeting.
- Keep server-only secrets out of the client runtime.

## Session Contracts

- Token endpoint: returns `{ token, uid, channel }` and may include `agentId` once the session starts.
- Invite endpoint: accepts `{ requester_id, channel_name }` and returns `{ agent_id, create_ts, state }`.
- Stop endpoint: accepts `{ agent_id }` and returns success for already-stopping or stopped agents.

## Event Contracts

- Transcript updates.
- Agent state updates.
- Metric events.
- Error or connection events.
