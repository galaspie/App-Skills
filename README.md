# App-Skills

Source repo for Claude Code skills. Each skill gets its own subfolder.
Work happens here; publish (deploy) to the live skill location when ready.

## Skills

- `orchestrator/` — two-engine (Claude + Codex) sprint-proposal process.

## Workflow

1. Edit a skill's `SKILL.md` inside its subfolder here.
2. When ready to publish, run that skill's `deploy.sh` — copies `SKILL.md`
   to `~/.claude/skills/<name>/SKILL.md`, the fixed location Claude Code
   actually loads skills from.
3. Commit here as normal. The live `~/.claude/skills/` copy is a deploy
   target, not something to edit directly.
