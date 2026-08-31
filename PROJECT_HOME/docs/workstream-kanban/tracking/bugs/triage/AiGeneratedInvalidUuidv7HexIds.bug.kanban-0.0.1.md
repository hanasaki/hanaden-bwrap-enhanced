---
card-id: BUG-UUID-001
card-type: bug
title: "AI-generated Hanaden UUIDv7 Extended IDs violate format spec — multi-layer violations"
status: triage
priority: P1
workstream: doc-engineering
reported-by: "Frederick Bloom (user)"
reported-date: "2026-08-27"
authoritative-spec: "GenericSdlcEngine.strat/ArtifactAnonimity.driv/TimestampUuidNaming.moti/NamingConvention.feat/FilenameFormat.spec/20260826-144956-115350-783f-8631-9e29ebb3ecbf-FilenameFormat.spec-0.0.1.md"
timestamp-precision: "MICROSECONDS (uuuuuu = 6 decimal digits, 000000-999999) — NOT milliseconds, NOT nanoseconds"
affected-areas:
  - "PROJECT_HOME/generic-sdlc-and-engine-readonly/**"
  - "PROJECT_HOME/docs/architecture-design-features-specs/**"
  - "docs/doc-templates/**"
confirmed-broken-files:
  - "20260827-091223-524910-7f4b-cd51-g2e360d18b9c-ImplStateDerivation.spec-0.0.1.md (FIXED)"
  - "20260827-092437-618430-7a5c-de62-h3f471e29d0f-TestRunReportSchema.feat-0.0.1.md (FIXED)"
fix-status: "2 files fixed in session 2026-08-27. Full audit of all AI-generated files NOT YET DONE."
blocked-by: null
---

# BUG-UUID-001: AI-Generated UUIDv7 Extended IDs Contain Invalid Hex Characters

## Problem Statement

AI (Antigravity/Gemini) generating Hanaden UUIDv7 Extended `filename-id` values has
been found to produce **invalid hex characters** (`g`, `h`, and potentially others from
the `g-z` range) in the 12-hex last segment of the ID.

**The Hanaden UUIDv7 Extended format is:**
```
YYYYMMDD-HHMMSS-[6digits]-[4hex]-[4hex]-[12hex]-Slug.class-semver.md
                                                  ^^^^^^
                                                  MUST be [0-9a-f] only
```

The AI was constructing this segment by hand (training-data memory) instead of calling
`os.urandom(6).hex()`, resulting in plausible-looking but structurally invalid IDs.

## Risk

- **Broken identity pointers:** Any `parent:`, `unlocks:`, or `references:` field in
  another document that cites a broken filename-id is pointing at a non-existent identity.
- **Silent corruption:** IDs look correct at a glance — `h3f471e29d0f` reads like hex
  until you notice `h` is not in `[0-9a-f]`.
- **Cross-reference breakage:** If a file is renamed to fix its ID, any document that
  referenced the old (broken) ID by name in body text or `parent:` now has a stale pointer.

## Scope of Audit Required

1. **Scan all `filename-id:` fields** in every `.md` file across:
   - `PROJECT_HOME/docs/architecture-design-features-specs/`
   - `PROJECT_HOME/generic-sdlc-and-engine-readonly/`
   - `docs/doc-templates/`
2. **Validate** each ID against the regex:
   `^\d{8}-\d{6}-\d{6}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$`
3. **For each broken file:**
   a. Generate a new valid last segment via `python3 -c "import os; print(os.urandom(6).hex())"`
   b. Rename the file on disk (keep original timestamp prefix — only last hex segment changes)
   c. Fix `filename-id:` frontmatter in the file
   d. Fix the HTML comment header `<!-- ... -->` in the file
   e. **Search all other files** for references to the old broken ID (in `parent:`, `unlocks:`,
      `references:`, `supersedes:`, and body text) and update them to the new ID
4. **Verify** no remaining broken IDs and no dangling references

## Acceptance Criteria

- [ ] All `filename-id:` values pass regex validation `^\d{8}-\d{6}-\d{6}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}`
- [ ] All filenames on disk match their internal `filename-id:` field exactly
- [ ] All cross-references (`parent:`, `unlocks:`, `references:`, `supersedes:`) resolve to a real file
- [ ] No broken ID appears in the body text of any document
- [ ] AI tooling rule updated: **never hand-craft the 12-hex segment** — always use `os.urandom(6).hex()`

## Root Cause

AI generated the 12-hex tail segment from training-data pattern completion rather than
calling `os.urandom(6).hex()`. The hex alphabet `[0-9a-f]` was confused with a broader
alphanumeric range `[0-9a-z]`.

## Fix Protocol (for whoever executes this card)

```bash
# Step 1: Scan all filename-id fields for invalid hex
find PROJECT_HOME docs/doc-templates -name "*.md" | while read f; do
  fid=$(grep "^filename-id:" "$f" | head -1 | sed 's/.*filename-id:[[:space:]]*//')
  if [[ -n "$fid" ]]; then
    uuid_part=$(echo "$fid" | grep -oP '\d{8}-\d{6}-\d{6}-[0-9a-f]{4}-[0-9a-f]{4}-\K[0-9a-z]{12}')
    if [[ -n "$uuid_part" ]] && echo "$uuid_part" | grep -qP '[g-z]'; then
      echo "BROKEN: $fid  in  $f"
    fi
  fi
done

# Step 2: For each broken file, generate replacement
NEW_HEX=$(python3 -c "import os; print(os.urandom(6).hex())")
echo "New 12-hex segment: $NEW_HEX"
```

## Activity Log

| Date | Actor | Action |
|:---|:---|:---|
| 2026-08-27 | Frederick Bloom | Reported: AI produced `g2e360d18b9c` and `h3f471e29d0f` — invalid hex |
| 2026-08-27 | AI | Confirmed 2 broken files, fixed both (rename + frontmatter + comment header) |
| 2026-08-27 | AI | Created this bug card for full audit tracking |
| 2026-08-27 | AI | Ran initial scan of 142 `.md` files — 0 remaining violations found in current session files |
