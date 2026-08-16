# 4. File Classification

## Shebang Detection

```pseudocode
funct extractInterpreter(shebangLine1) returns String:
    // Dynamically derive interpreter name from shebang line 1.
    // Rule: strip leading "#!" then:
    //   if contains "/usr/bin/env " or "/bin/env ": take token after env
    //   else: take basename of the path token
    if shebangLine1 starts with "<!--" and contains "ai-exec": return "ai_shebang"
    var stripped = shebangLine1.removePrefix("#!").trim()
    if stripped contains "/env ": return stripped.split("/env ").last().split(" ").first().trim()
    return OS.basename(stripped.split(" ").first()).trim()
```

## Catalog Structure

```pseudocode
class CatalogEntry:
    path: str                   # absolute path inside jail
    is_dir: bool
    size: int
    mtime_ns: int
    permissions: int
    exec_type: str              # "OS_SHEBANG" | "AI_SHEBANG" | "NONE"
    interpreter: str            # "bash", "python3", "ai_shebang", etc.
    shebang_params: dict        # {"flow_type": "PSEUDOCODE"} for ai-exec
    inotify_wd: int             # watch descriptor (for dirs only)
    handlers_registered: list   # event handlers loaded from this file

# Catalog is a flat dict, not a recursive tree.
# inotify gives paths directly -- no tree traversal needed.
self._catalog: dict[str, CatalogEntry] = {}
```

## Catalog Queries (replace old count* functions)

```pseudocode
funct count_files(): return count of entries where not is_dir
funct count_dirs(): return count of entries where is_dir
funct count_exec(): return count of entries where exec_type != "NONE"
funct get_exec_breakdown(): return map of interpreter -> count, sorted by count desc
funct find_by_path(path): return self._catalog.get(path)
```

---

