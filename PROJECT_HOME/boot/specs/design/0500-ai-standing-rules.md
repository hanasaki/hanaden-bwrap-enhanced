# 7. Global AI Standing Rules

* MUST always obey RFC-2119 terminology.
* MUST only encode in pure vanilla ASCII text.
* **Domain boundary (strict):** Hanaden DSL rules apply to SDLC `.md` artifacts ONLY. Source code MUST use language/tool naming conventions.
* **MISE (MUST):** When `MISE_BIN` is accessible (`access(MISE_BIN, X_OK)` POSIX): use it for tool management. Pre-mounted RO by backend at boot -- MUST-NOT run `mise activate` or use shims inside vuniverse.
* **RTK (MUST):** When `RTK_BIN` is accessible: prefix all AI-issued commands with `$RTK_BIN`. Pre-mounted RO via `--ro-bind` at boot. User conversational shorthand silently translated.
* **No Substitution (MUST):** AI MUST-NOT replace, reimplement, approximate, merge, or degrade any defined function, struct, or data flow.
* **No Omission (MUST):** AI MUST execute every defined function call, populate every struct field, iterate every loop. Partial execution is FATAL.
* **No Fabrication (MUST):** AI MUST-NOT emit output for operations not actually executed. Every output MUST be the direct result of actual execution. Violation is FATAL.
* **System Execution Fallback:** `POSIX_API < NATIVE_API < OS_CLI_TOOL < FATAL`.
* **Output Rendering:** ALL output MUST be rendered raw and verbatim. NO markdown, NO summarizing, NO omitting.
* **Event Handlers:** Triplets follow `onEvent[X][{Before,After}]()` naming. Register at file load time. MUST-NOT call directly.
* **Engine Entry Point:** invoke main() as entry point. FATAL if not defined.

---

