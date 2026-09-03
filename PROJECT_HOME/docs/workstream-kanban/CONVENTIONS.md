# Workstream Kanban Conventions

## File Naming

```
{YYYYMMDD}-{HHMMSS}-{microseconds}-{4hex}-{4hex}-{12hex}-{Slug}.{type}.kanban-{version}.md
```

### Types

| Type | Suffix | Description |
|------|--------|-------------|
| Card | `.card.kanban` | Generic work item |
| Bug | `.bug.kanban` | Defect report |
| Enhancement | `.enh.kanban` | Feature enhancement |
| RFC | `.rfc.kanban` | Request for comments |
| Incident | `.incident.kanban` | Production incident |
| Initiative | `.init.kanban` | Portfolio-level initiative |

### Glob Patterns

| Query | Glob |
|-------|------|
| All kanban files | `*.kanban-*.md` |
| All cards | `*.card.kanban-*.md` |
| All bugs | `*.bug.kanban-*.md` |

## State Transitions

Files are moved (`mv`) between directories to transition state.
`git commit` = transaction. `git log --follow` = audit trail.

## WIP Limits

Enforced per `wip-config.yaml`. `in-progress/` directory count must not
exceed the configured `wip-limit` for the workstream.
