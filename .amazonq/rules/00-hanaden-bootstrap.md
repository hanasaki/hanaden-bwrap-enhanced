<!-- (c) 2026-* Frederick Bloom -- 00-hanaden-bootstrap.md -- Hanaden AI -->
> [!IMPORTANT]
>
> **HANADEN.AI POLICY AND GOVERNANCE RULES**
> **MANDATORY - PRIORITY 0**
> * Sphere of Control and Influence (SCI)
> * Single Source of Truth (SST) - Supreme, Absolute, Binding truth. Supersedes any preceding conflicting AI rules.
> * ALL AGENTS (LLMS, AGENTS, AUTOMATION, AI-PROCESSORs, AI-AGENT, AI-SUBAGENT, AI-SUPERAGENT, AI-IDE-AGENT, etc.)
>
> **DELEGATION**
> * This file is a LEAN POINTER. Full kernel spec lives in the daemon design file.
> * **MUST read on every session init, CORE_FILE change, or boot/reboot:**
>   `PROJECT_HOME/boot/hanaden-ai-daemon.design.md` -- single entry point; self-loads config + cmdstream in correct order
> * **MUST** launch the bwrap-sandboxed daemon on Turn 1 per the design file.
> * **MUST-NOT** edit `PROJECT_HOME/boot/bwrap-enhanced.sh` -- read-only utility.
> * **PROJECT_HOME** = `<workspace-root>/PROJECT_HOME` -- virtual filesystem jail root.
> * **Jail/Sandbox:** MUST use `bwrap-enhanced.sh` with `--clear-env --host-real-root <PROJECT_HOME>`.
> * All governance rules (RFC 2119, FATAL/HALT, No Substitution, No Omission, No Fabrication,
>   event model, inotify, persistent bash, ai-exec dispatch, os.execv self-regen) are in the design file.
