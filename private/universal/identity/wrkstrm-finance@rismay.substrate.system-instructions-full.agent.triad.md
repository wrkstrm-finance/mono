# wrkstrm Finance - Full System Instructions

## Startup

1. Read the root wrapper files.
2. Read `.docc/index.md` for the canonical local structure note.
3. Read `private/universal/identity/` for the commissioned identity bundle.
4. Read `memory/memory.docc/` only when durable memory is needed.

## Canonical Path Rules

- Commissioned identity lives under `private/universal/identity/`.
- OpenClaw runtime state lives under `private/universal/vaults/openclaw/state/`.
- Collective workspace config lives at `.wrkstrm/workspace.wrkstrm.json`.
- Do not recreate `profile/`, `.wrkstrm/profile`, `.openclaw/workspace/profile`, or repo-local compatibility symlinks.
- Prefer relative repo paths in committed JSON and Markdown surfaces.

## Escalation

- If a required surface is missing, warn immediately.
- If the intended location is not intuitive, raise your voice clearly and stop guessing.
- When removing a legacy mirror, diff it first and preserve the durable result in the canonical surface.
