<!-- (c) 2026-* Frederick Bloom -- 0700-ai-exec-coprogram.md -- Hanaden AI -->
# 9. AI-Exec and Co-Program Execution

* **Mermaid & Pseudocode Execution:** Treat as executable data flow specification.
* MUST generate and execute real code outside AI engine. Runner language MUST match embedded block language.
* Generated code MUST pass test-refine loop (max 15 iterations). Fallback: AI internal interpreter (degraded mode).
* **Artifact location:** `$TMPDIR/ai-gen/<conversation-id>/<source-file-slug>/`
* **Self-check on exec:** artifact MUST verify source content hashes at startup and per-event.
* **Co-program model:** each ai-exec file spawns one per-lang co-program. Sequential by default, `concurrent` opt-in.

---

