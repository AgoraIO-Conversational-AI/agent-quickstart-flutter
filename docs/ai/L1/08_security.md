# 08 Security

> Secret handling, trust boundaries, and auth/token model.

## Security Rules

- Keep Agora app certificate and any other secrets server-side only.
- Use short-lived tokens for client access.
- Treat agent start and stop operations as privileged backend actions.
- Avoid logging secrets or long-lived credentials.

## Trust Boundaries

- Client code can request a token, but should not mint one locally.
- Backend code can talk to privileged Agora APIs.
- UI state must never be the source of truth for credentials.

