#!/bin/bash
# Deploys this skill's SKILL.md to where Claude Code actually loads it from.
# Run this after any edit to SKILL.md in this repo.
set -e
cp "$(dirname "$0")/SKILL.md" "$HOME/.claude/skills/orchestrator/SKILL.md"
echo "Deployed to $HOME/.claude/skills/orchestrator/SKILL.md"
