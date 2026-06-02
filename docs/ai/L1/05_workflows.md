# 05 Workflows

> Common task recipes for run, modify, validate, and ship.

## Build and Run

1. Fetch dependencies.
2. Run static checks.
3. Launch the target platform.
4. Verify the session flow.

## Change Workflow

1. Identify the smallest file set that owns the behavior.
2. Update the code and the matching doc page together.
3. Re-run the narrowest validation command.
4. Expand only if the change touches multiple layers.

## Ship Workflow

1. Verify the client app.
2. Verify backend contracts if they exist.
3. Check that docs still match the implementation.
4. Keep the commit scope small and reviewable.

