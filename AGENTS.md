# Agent Development Guide

This guide is for coding agents making changes in `agent-quickstart-flutter`.

## How to Load

Use progressive disclosure so future work stays low-context:

1. Read [README.md](./README.md) for the user-facing setup and run flow.
2. Read [docs/ai/L0_repo_card.md](docs/ai/L0_repo_card.md) to identify the repo contract.
3. Load the [docs/ai/L1/](docs/ai/L1/) summaries that match the task.
4. Open L2 deep dives only when L1 is not enough.

## Start Here

- Treat this repository as the Flutter counterpart to the Next.js quickstart.
- Keep changes small and commit-sized.
- Prefer the smallest implementation that preserves the end-to-end contract.
- If a repeated workflow would benefit from a custom skill or MCP server, add it only after the need is proven.

## Current System Shape

- Flutter client for the browser/mobile UI.
- Small backend companion for token generation, agent invite, and stop flows.
- Agora RTC for audio transport.
- Agora RTM for transcript, agent state, metrics, and error events.
- Shared domain models and transform helpers under `lib/`.

## Repository Ownership

- `lib/` owns app state models, UI helpers, and transcript/event transforms.
- `backend/` or the chosen server slice owns privileged token and agent lifecycle operations.
- `docs/` owns the agent-facing contract and runbook.
- `README.md` owns the concise setup and usage path for humans.

## Working Rules

- Keep privileged Agora credentials server-side only.
- Keep the client session lifecycle isolated from build-time configuration.
- Prefer docs and small helpers over repeated inline explanations.
- When workflows or contracts change, update the relevant `docs/ai/` files in the same change.

## Low-Token Workflow

- Read the narrowest doc set that answers the task.
- Reuse existing names and contracts instead of inventing new ones.
- Favor one focused file per responsibility.
- Avoid adding tooling unless it removes repeated manual work.

## Verification

- Run the narrowest check that proves the change.
- Update docs first when the change is about workflow, interface, or architecture.
- Keep future code changes aligned with this repo contract.

## Git Conventions

- Branch names: `codex/<short-description>`.
- Commit messages: conventional commits such as `docs:`, `feat:`, `fix:`, or `chore:`.
