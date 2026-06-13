<div align="center">

# Claude Code Hooks

**Production-grade hook system for Claude Code**

*Quality gates, circuit breakers, skill activation, audit trails — 15 battle-tested hooks.*

[![Claude Code](https://img.shields.io/badge/Claude_Code-hooks-blue?style=for-the-badge)](https://docs.anthropic.com/en/docs/claude-code/hooks)
[![Hooks](https://img.shields.io/badge/hooks-15-emerald?style=for-the-badge)](#hooks)
[![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)](LICENSE)

</div>

---

## What Are Hooks?

Claude Code hooks are shell scripts and Node.js modules that run automatically during AI coding sessions. They intercept lifecycle events — before edits, after tool calls, on session start/stop — giving you control over quality, safety, and intelligence.

Supports the full 5-harness fleet + grok-personal excellence layer (the 4 .grok-native seeds + personal-creative per claude-code-config/SHARING.md). Excellence gates (quality-gate, pre-compact) enforce Frank DNA + rules first + core vs grok-personal/personal-creative partition. Portable across Claude, Grok TUI, agy, gemini. See SHARING.md for the "a bit magical, not for everything" discipline.

```
You edit a file → Quality Gate checks token compliance → PASS → Edit proceeds
You edit a file → Quality Gate detects hardcoded color → BLOCK → Suggests token
```

## Install

```bash
git clone https://github.com/frankxai/claude-code-hooks.git
cd claude-code-hooks
./install.sh
```

Or copy individual hooks to your `.claude/hooks/` directory.

**Multi-harness / Grok support:** `./install.sh --multi` or `--portable` seeds for claude/codex/gemini/agy/grok (via hook-env detection). For Grok, also seeds `~/.grok/hooks/*.json` for native SessionStart/PreToolUse excellence gates (Kenya-magical per SHARING.md + SIP §5: the excellence hooks stay sovereign in .grok/ only; core hooks portable to all). Kenya magical (Grok .grok excellence tuned for TUI/subagents/MCP/image + personal) not shared to ACOS core.

## The 15 Hooks

### Lifecycle: Session Start
| Hook | Purpose |
|------|---------|
| `session-start.js` | Initialize session context, load previous state |
| `skill-activation-prompt.sh` | Auto-detect project context and load matching skills |

### Lifecycle: Pre-Tool Use (Before Edits)
| Hook | Purpose |
|------|---------|
| `quality-gate.sh` | Block edits that violate code standards, token compliance |
| `circuit-breaker.sh` | Detect retry loops and halt before wasting context |
| `self-modify-gate.sh` | Prevent AI from modifying its own configuration |

### Lifecycle: Post-Tool Use (After Actions)
| Hook | Purpose |
|------|---------|
| `post-tool-track.js` | Track tool usage patterns for learning |
| `audit-trail.sh` | Append-only log of every file modification |
| `circuit-breaker-post.sh` | Count failures: 3 warn, 5 restrict, 8 block |
| `context-budget-tracker.ts` | Monitor context window usage |
| `activation-logger.sh` | Log which skills activated and why |

### Lifecycle: User Prompt Submit
| Hook | Purpose |
|------|---------|
| `skill-activation-prompt.js` | Match keywords to skills, load context |

### Lifecycle: Pre-Compact (Before Context Compression)
| Hook | Purpose |
|------|---------|
| `context-preservation.sh` | Save critical context before compression |

### Lifecycle: Stop (Session End)
| Hook | Purpose |
|------|---------|
| `stop-finalize.js` | Save session state, generate summary |
| `session-end-log.sh` | Log session metrics and outcomes |
| `session-logger.sh` | Persistent session history |

## How It Works

### Quality Gate (Pre-Edit)

The quality gate runs before every `Edit`, `Write`, or `NotebookEdit` tool call:

```bash
# .claude/hooks/quality-gate.sh
# Triggered: PreToolUse [Edit|Write|NotebookEdit]

# Check for hardcoded colors (should use tokens)
if grep -qP '#[0-9a-fA-F]{6}' "$FILE"; then
  echo "BLOCK: Use design tokens instead of hardcoded hex colors"
  exit 1
fi
```

### Circuit Breaker (Post-Edit)

Prevents infinite retry loops:

```bash
# Tracks consecutive failures per tool
# 3 failures → WARNING
# 5 failures → RESTRICTED (suggest alternative)
# 8 failures → BLOCKED (force stop)
```

### Skill Activation (Prompt Submit)

Automatically loads relevant skills based on what you're working on:

```javascript
// Detects: file patterns (.tsx → react-patterns)
// Detects: keywords ("blog post" → article-creator)
// Detects: magic words ("ultrawork" → swarm mode)
```

## Configuration

Add hooks to your `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write|NotebookEdit",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/quality-gate.sh" }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|NotebookEdit|Bash",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/audit-trail.sh" }
        ]
      }
    ]
  }
}
```

## Part of ACOS

These hooks are extracted from the [Agentic Creator OS](https://github.com/frankxai/agentic-creator-os) — a full operating system for AI coding agents with 90+ skills, 65+ commands, and 38 agents.

## License

MIT
