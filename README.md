# openclawpatch4claudecodecli

A tiny patch for OpenClaw's built-in `claude-cli` backend.

## Problem

When OpenClaw calls Claude Code CLI through its built-in `claude-cli` backend, the full injected OpenClaw system prompt can trigger Claude-side usage errors such as:

> Third-party apps now draw from your extra usage, not your plan limits.

Direct `claude --print` calls still work, so the failure is specific to OpenClaw's prompt injection path.

## Workaround

Replace the huge injected system prompt with a short workspace-lite boot prompt.

The short prompt tells Claude to reconstruct context from local files such as:

- `AGENTS.md`
- `SOUL.md`
- `IDENTITY.md`
- `USER.md`
- `TOOLS.md`
- `HEARTBEAT.md`
- `BOOTSTRAP.md` (if present)
- `MEMORY.md`
- `memory/<today>.md`
- `memory/<yesterday>.md`

## File

- `openclaw-claude-cli-workspace-lite.patch`

## Notes

This is a pragmatic workaround, not a polished upstream feature.
A cleaner long-term fix would be adding a configurable `workspace-lite` boot mode to OpenClaw's `claude-cli` backend.
