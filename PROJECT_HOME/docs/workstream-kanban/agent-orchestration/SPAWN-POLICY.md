# Agent Spawn Policy — Exponential Backoff

## Algorithm

```
spawn_budget(depth) = floor(BASE_BUDGET / 2^depth)

BASE_BUDGET = 8

depth=0 → budget=8   (orchestrator)
depth=1 → budget=4
depth=2 → budget=2
depth=3 → budget=1
depth=4 → budget=0   (HARD STOP)
```

## Rules

1. Before spawning, check `spawn_budget(current_depth + 1) > 0`. If 0, HALT.
2. Agent at depth `d` can have at most `spawn_budget(d)` active children.
3. If budget is 0 and work cannot complete, escalate with `blocked-reason: depth-limit-exceeded`.
4. No budget laundering: each level must do meaningful work before spawning.
5. Every spawn writes `dispatch-log/` entry with `parent-depth`, `child-depth`, `remaining-budget`.
