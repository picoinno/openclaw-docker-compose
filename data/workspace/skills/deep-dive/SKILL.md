---
name: deep-dive
description: "Spawn Nexus (Opus-powered) for deep research, reasoning, and analysis tasks. Use when the user asks to think through, research, analyze deeply, reason step by step, do a deep dive, or explore tradeoffs. Triggers on: deep dive, think through, reason through, research this, analyze thoroughly, explore options, what are the tradeoffs, think harder, serious analysis."
---

# Deep Dive — Nexus Skill

Route complex thinking and research tasks to Nexus, the Opus-powered deep thinking agent.

## When to Invoke

Trigger phrases (any of these warrant spawning Nexus):
- "deep dive", "think through", "reason through"
- "research this / research thoroughly"
- "analyze this carefully / analyze in depth"
- "what are the tradeoffs / pros and cons"
- "think harder", "think step by step"
- "explore options", "help me decide"
- "serious analysis", "thorough review"

Also invoke proactively when:
- The question is multi-layered with no obvious answer
- The task requires connecting information across multiple domains
- A decision has significant consequences
- Architecture, design, or strategy is being discussed

## How to Invoke

Spawn Nexus as a subagent, pass the full task with context:

```
sessions_spawn(
  task: "<full task description with all relevant context>",
  agentId: "main",  // uses workspace agent persona
  label: "nexus",
  runtime: "subagent",
  mode: "run",
  streamTo: "parent"
)
```

Pass enough context so Nexus doesn't need to ask for basics:
- What the user is trying to decide or understand
- Relevant background (project, constraints, prior decisions)
- What kind of output is expected (recommendation, analysis, options list)

## Output Handling

- Stream results back to the user as Nexus works
- After Nexus completes, summarize the key conclusion in 1-2 sentences
- If the result is long, offer to break it down further

## Model Note

Nexus uses Opus — it's slower and more expensive than Sonnet.
Only invoke for tasks that genuinely need it. Routine questions stay with the primary agent.
