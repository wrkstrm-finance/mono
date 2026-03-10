# AGENTS.md - wrkstrm Finance Entrypoint

This file is a thin entrypoint wrapper.

Canonical placeholder pack:

- `../agents/root/AGENTS.md`

Preferred commissioned collective home:

- `./`

Current commissioned collective home:

- `./`

## Startup

1. Read this wrapper.
2. Load commissioned artifacts from `./`.
3. Fall back to `../agents/root/*.md` only when a surface is missing.
4. Avoid tooling, auth, or build surfaces during startup unless the task requires them.

## Notes

- The top-level `wrkstrm-finance` files are wrappers, not the canonical source of collective-specific state.
- Keep collective-specific state under canonical repo-local surfaces such as `private/universal/identity/`, `private/universal/vaults/openclaw/state/`, and `memory/memory.docc/`.
- Treat `workspace` as the primary working home.
- Keep the commissioned identity in `private/universal/identity/`.
- Keep canonical memory in `memory/memory.docc/`.
- Keep OpenClaw runtime state in `private/universal/vaults/openclaw/state/`.
- Do not add repo-local compatibility symlinks, root alias paths, or legacy profile mirrors.
- If a surface is missing and the location is not intuitive, warn and raise your voice instead of guessing.
