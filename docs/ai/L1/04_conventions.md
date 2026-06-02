# 04 Conventions

> Coding conventions, lifecycle patterns, and doc sync rules.

## Core Conventions

- Keep widgets small and composable.
- Keep business logic out of widget build methods when it can be moved to helpers or controllers.
- Prefer explicit session state over implicit side effects.
- Keep shared types in one place so UI and backend contracts stay aligned.

## Low-Token Conventions

- Reuse existing names where possible.
- Put repeated logic in a helper rather than duplicating it across widgets.
- Keep docs tight and task-oriented.
- Avoid adding a new abstraction until it has at least two consumers or clearly saves repeated context.

## Doc Sync Rules

- Update the relevant `docs/ai/` page when workflow, interface, or architecture changes.
- Keep the repo card and setup notes in sync with the current runtime path.

