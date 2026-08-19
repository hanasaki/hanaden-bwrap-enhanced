<!-- (c) 2026-* Frederick Bloom -- 0045-lang-profile.md -- Hanaden AI -->

## Language Profile Configuration

```toml
[lang]
# Separate allowed lists per environment.
# The active environment is determined by HANADEN_ENV (env var, default: "dev").
langs_allowed_dev  = ["python", "rust-script", "rust", "go", "zig"]
langs_allowed_prod = ["rust", "go", "zig"]

# Selection mode (per environment):
#   "locked"           — Always use lang_locked. No choice, no probing.
#   "ai-choice"        — AI selects from langs_allowed case-by-case.
#                         MUST only choose from the active allowed list.
#                         MUST log choice and reasoning.
#   "first-available"  — Iterate allowed list in order, probe runtime
#                         in sandbox, select first that passes. FATAL if none.

[lang.dev]
lang_choice = "locked"
lang_locked = "rust-script"

[lang.prod]
lang_choice = "locked"
lang_locked = "rust"
```

## Startup Performance (reference)

| Language | Startup Class | Cold Start | Warm/Cached | Notes |
|----------|--------------|------------|-------------|-------|
| Rust (binary) | instant | ~1–5ms | ~1–5ms | Static binary, no runtime |
| Go (binary) | instant | ~1–5ms | ~1–5ms | Static binary, minimal runtime |
| Zig (binary) | instant | ~1–5ms | ~1–5ms | Static binary, no runtime |
| Rust-script | slow-first, fast-cached | ~5–30s (compile) | ~200–500ms (cached) | `cargo -Zscript` caches between runs |
| Python | moderate | ~100–300ms | ~100–300ms | Interpreter + imports (asyncio, ctypes, json) |

> [!NOTE]
> Python "taking forever" in practice is usually the full AI-generation cycle:
> AI generates source → `py_compile` validates → bwrap launches → python3 starts → imports → event loop ready.
> The interpreter startup itself is ~100-300ms, but the generation + validation adds seconds.
> Compiled languages eliminate the interpreter tax but add a compile step (unless pre-built).

## Profile Contract

Each `config/0050-lang-profile-<name>.md` MUST define these fields:

```
interpreter        — runtime binary (empty string if compiled)
filename           — generated daemon filename
file_ext           — source file extension
entry_cmd          — full command to launch daemon in sandbox
syntax_check_cmd   — syntax validation command ({file} placeholder)
event_loop         — event loop framework/mechanism
inotify_binding    — inotify integration method
process_replace    — process image replacement API (MUST use execve with
                     explicit envp built from config/0055-vuniverse-env.md,
                     NOT execv which blindly inherits env)
startup_class      — "instant" | "moderate" | "slow-first"
```

Each profile MAY also define:

```
[anti_regression]  — lang-specific mandates (RFC 2119)
stdlib_only        — whether external packages are forbidden
shebang            — interpreter shebang line (for script-mode langs)
compiled           — whether a separate compile step is required
```

