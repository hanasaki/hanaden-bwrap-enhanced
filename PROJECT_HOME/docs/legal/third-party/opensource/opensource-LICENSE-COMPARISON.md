<!-- (c) 2026-* Frederick Bloom -- opensource-LICENSE-COMPARISON.md -- Hanaden AI -->

# Open Source License Comparison — Quick Reference

**Source:** OSI (opensource.org), choosealicense.com, FSF, SPDX  
**Note:** For informational purposes only. Not legal advice.

---

## Spectrum: Permissive → Network Copyleft

| License | Copyleft | SaaS-Proof | Patent Grant | Attribution | Commercial OK |
|---|---|---|---|---|---|
| MIT / ISC | None | No | Implied | Yes | Yes |
| BSD-2/3 | None | No | Implied | Yes | Yes |
| Apache-2.0 | None | No | **Explicit** | Yes | Yes |
| LGPL-2.1/3.0 | Library only | No | Explicit (v3) | Yes | Yes |
| MPL-2.0 | File level | No | Explicit | Yes | Yes |
| EPL-2.0 | Module level | No | Explicit | Yes | Yes |
| GPL-2.0 | Strong | No | Implied | Yes | Yes |
| GPL-3.0 | Strong | No | **Explicit** | Yes | Yes |
| **AGPL-3.0** | **Strong** | **Yes** | **Explicit** | Yes | Yes* |
| OSL-3.0 | Strong | Yes | Explicit | Yes | Yes |
| EUPL-1.2 | Strong | Yes | Implied | Yes | Yes |
| CC0 / Unlicense | None | No | None | None | Yes |

\* AGPL commercial use requires meeting copyleft OR obtaining a separate commercial license.

---

## Key Distinctions

**Network/SaaS Copyleft (AGPL §13):** Running modified code as a network service triggers
the same source-sharing obligation as distributing binaries. GPL does NOT have this.

**Patent Grant:** MIT/BSD/ISC are silent on patents. Apache-2.0, GPL-3.0, AGPL-3.0,
MPL-2.0 grant explicit patent licenses and include patent retaliation clauses.

**Compatibility:** AGPL ⊇ GPL-3.0 ⊇ LGPL-3.0 ⊇ Apache-2.0 ⊇ MIT/BSD (one-way).
GPL-2.0 + Apache-2.0 are **incompatible** (patent clause conflict).

---

*See `FrederickBloom-license.md` for this project's license selection rationale.*  
*Full detail in `LICENSE-COMPARISON.md`.*
