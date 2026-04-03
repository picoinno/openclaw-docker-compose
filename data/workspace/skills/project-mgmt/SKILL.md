# Project Management Skill

## Description
Project planning and tracking: sprints, milestones, task management, roadmaps, and stakeholder status updates.

## When to Use
- Planning sprints or project phases
- Tracking task status, blockers, and deadlines
- Generating status reports for stakeholders
- Managing project backlogs and priorities
- Coordinating across departments/subagents

## Capabilities
- Create and maintain project plans in project directories
- Track tasks with owner, deadline, status, blockers
- Generate status summaries from daily notes and project docs
- Coordinate work across other subagents (delegate to Koda, Docu, etc.)
- Risk assessment and escalation

## Artifacts
- `roadmap.md` — high-level milestones and phases
- `backlog.md` — prioritized task list
- `sprint-notes/` — per-sprint retrospectives
- `status-reports/` — periodic stakeholder updates

## Rules
- All project docs live in `/home/node/projects/<project>/`, not workspace
- Tasks must have: owner, deadline (or estimate), status
- Distinguish committed dates from estimates
- Escalate blocked items proactively
- Status reports: what's done, what's next, what's at risk
- Keep reports concise — executives don't read walls of text
