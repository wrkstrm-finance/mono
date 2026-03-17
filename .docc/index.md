@Metadata {
  @TechnologyRoot
  @PageKind(article)
  @PageColor(gray)
  @TitleHeading("wrkstrm Finance")
  @Available(platform: macOS, introduced: "1.0")
}

# wrkstrm Finance

This is the canonical DocC entrypoint for the local `wrkstrm-finance` collective scaffold.

## Purpose

- This directory is the canonical collective workspace for `wrkstrm-finance`.
- Canonical local structure guidance for this scaffold lives in this DocC bundle.

## Structure

- `private/universal/identity` - canonical commissioned identity / triad home
- `memory/memory.docc` - canonical memory surface
- `private/universal/vaults/openclaw/state/agent` - canonical OpenClaw agent-local state
- `private/universal/vaults/openclaw/state/agent/auth-profiles.template.json` - committed auth template
- `private/universal/vaults/openclaw/state/sessions` - canonical OpenClaw session store
- `.wrkstrm/workspace.wrkstrm.json` - current CLIA workspace contract
- `private/universal/archive/legacy-profiles` - archived copy of historical `.wrkstrm/profiles/**` content

## Local Metadata Sources

- `wrkstrm-finance.json`
- `wrkstrm-finance.reminder.json`

## OpenClaw Mapping

- When `wrkstrm-finance` is registered in OpenClaw, `~/.openclaw/agents/wrkstrm-finance` should resolve to the canonical workspace-owned state root.
- `~/.openclaw/agents/wrkstrm-finance/agent` should resolve to `private/universal/vaults/openclaw/state/agent`.
- `~/.openclaw/agents/wrkstrm-finance/sessions` should resolve to `private/universal/vaults/openclaw/state/sessions`.

## Canon

- Treat this page as the canonical local structure note for `wrkstrm-finance`.
- Keep commissioned identity in `private/universal/identity/`.
- Do not add repo-local alias paths or compatibility symlinks.
- If the right location is not intuitive, warn immediately and raise your voice instead of guessing.
