# Claude Code Hooks — Agent Instructions

This repo is part of the FrankX / Starlight / Arcanea agent estate.

## Classification

- Repo: `claude-code-hooks`
- Class: portable hook library, extracted from `agentic-creator-os`
- Default health command: `for f in hooks/*.sh; do bash -n "$f" || echo "FAIL $f"; done` (syntax check; no automated test runner exists — `test/_evidence/hooks-tests.log` is a manually captured log, not a script)
- Remote: https://github.com/frankxai/claude-code-hooks

## What this repo is

A portable Claude Code (+ Codex/Gemini/agy/Grok) hook library: `hooks/*.sh` are thin multi-harness wrappers (via `hooks/lib/hook-env.sh`) around `.js`/`.ts` implementations. `settings-example.json` is the canonical wired configuration — the source of truth for which hooks are actually active vs. experimental/unwired. `install.sh` copies hooks into a target repo's `.claude/hooks/`; `install.sh --multi`/`--portable` also seeds Grok-native `.grok/hooks/*.json`.

## Agent Rules

- Read this file before making changes.
- Preserve existing user work and unrelated dirty files.
- Keep edits scoped to the requested task.
- Prefer existing repo conventions over new abstractions.
- Run the health command before handoff when feasible.
- Do not publish secrets, private memory, credentials, or internal-only strategy.

## Class-Specific Guidance

- Preserve skill/plugin/MCP schemas and frontmatter.
- Validate skills, manifests, scripts, and generated registries after edits.
- Keep public/private memory boundaries explicit.

## Handoff

Summarize changed files, validation run, risks, and any follow-up needed.

## Design Taste Kernel

For any site, app, landing page, dashboard, visual identity, brand, motion, media, social, or frontend task, apply the shared Design Taste Kernel before handoff:

- C:\Users\frank\starlight\repos\DESIGN_TASTE.md
- C:\Users\frank\starlight\repos\WEB_EXPERIENCE_STANDARD.md
- C:\Users\frank\starlight\repos\MOTION_TASTE_RUBRIC.md
- C:\Users\frank\starlight\repos\MULTI_AGENT_DESIGN_COUNCIL.md
- C:\Users\frank\starlight\repos\VISUAL_QA_GATE.md

When motion, scroll, generated media, GIF/video, or premium polish matters, route through the Motion Design Studio plugin/skills and verify the result visually.

