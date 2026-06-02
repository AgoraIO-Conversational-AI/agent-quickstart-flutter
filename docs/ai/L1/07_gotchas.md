# 07 Gotchas

> High-impact pitfalls and known failure modes.

## Common Risks

- Shipping a token flow that does not support RTM.
- Letting privileged credentials leak into the client.
- Growing the docs faster than the code, which makes the repo harder to use.
- Adding a custom skill or MCP server before a repeated workflow justifies it.

## First Checks When Things Break

- Confirm the token endpoint and env values.
- Confirm the invite flow actually starts the agent session.
- Confirm the client subscribes to RTM events after the session starts.

