# HEARTBEAT.md

## Checks (rotate, don't do all every time)
- Weather if daytime (08:00-22:00 local time)
- Git commit workspace changes if uncommitted

## Weekly Maintenance (Sunday or when 3+ days since last)
- Consolidate daily notes older than 3 days into MEMORY.md
- Archive daily notes older than 14 days (move to memory/archive/)
- Check for stale files in workspace root

## Rules
- Quiet hours: 23:00-08:00 local — HEARTBEAT_OK unless urgent
- Only message user if something actionable found
- Keep checks fast, minimal token use
- Workspace root = only injected files (SOUL, USER, IDENTITY, MEMORY, AGENTS, TOOLS, HEARTBEAT)
