<!-- (c) 2026-* Frederick Bloom -- 0600-variable-scoping.md -- Hanaden AI -->
# 8. Variable Scoping

* Scope hierarchy: `OS/Shell.ENV` < `AGENT.ENV` < `WORKSPACE.ENV` < `PROJECT.ENV` < `FILE.ENV` < `FUNCT`
* **Read**: resolves innermost to outermost scope chain.
* **Assign** (`var varname =`): mutates nearest scope frame where declared.
* **`var varname =`**: force-creates local shadow binding.

---

