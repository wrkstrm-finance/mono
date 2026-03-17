# BOOTSTRAP.md - wrkstrm Finance Entrypoint

wrkstrm Finance is already commissioned.

Preferred commissioned collective home:

- `./`

Current commissioned collective home:

- `./`

Load commissioned artifacts from `./` before considering any first-run bootstrap.

Use `../agents/root/BOOTSTRAP.md` only when recommissioning or repairing a missing commissioned home.

## Wake-Up Routine

Bootstrap should feel like waking up and trying to figure out where things live before doing work.

Startup order:

1. Read `AGENTS.md`.
2. Read `.docc/index.md`.
3. Read `AGENDA.md`.
4. Read `memory.md` and then prefer `memory/memory.docc/` for actual memory reads.

## Canonical Places

- local structure note: `.docc/index.md`
- canonical commissioned identity / triads: `private/universal/identity/`
- canonical memory: `memory/memory.docc/`
- canonical collective-local state: `private/universal/vaults/openclaw/state/agent/`
- canonical session store: `private/universal/vaults/openclaw/state/sessions/`
- collective workspace contract: `.wrkstrm/workspace.wrkstrm.json`
- OpenClaw-visible state root: `~/.openclaw/agents/wrkstrm-finance/` when registered

## Bootstrap Rules

- Keep runtime truth centralized in canonical config and identity surfaces rather than duplicated wrappers.
- Root workspace files act as orientation and pointer surfaces.
- Canonical memory is DocC-first; see `memory.md` and `memory/memory.docc/`.
- Keep the commissioned identity outside runtime state; use `private/universal/identity/` directly.
- Keep `stateDir` gateway-shaped and let OpenClaw-facing paths resolve into the workspace-owned state root.
- Do not introduce repo-local compatibility symlinks or alias paths when a canonical path already exists.
- In mono, run `clia core canonical-layout --kind collective wrkstrm-finance --path ~/mono` after layout changes.

## Missing Surface Behavior

- If an expected surface is missing, warn immediately instead of silently inventing a replacement.
- If the right location is not intuitive, say so plainly and ask for guidance before creating new structure.
- If bootstrap cannot find an essential surface needed to orient safely, raise its voice clearly and escalate the warning instead of guessing.
