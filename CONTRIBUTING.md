<!-- (c) 2026-* Frederick Bloom -- CONTRIBUTING.md -- Hanaden AI -->

# Contributing to bwrap-enhanced

## License

This is proprietary software. All contributions are subject to the project
license. By contributing, you agree that your contributions become the
property of Frederick Bloom under the same license terms.

## Branch Workflow

This project follows GitOps with a three-tier branch model:

```
feature/* → develop → master
```

1. **feature/*** — All work happens on feature branches created from `develop`
2. **develop** — Integration branch. Feature branches merge here via `--no-ff`
3. **master** — Release branch. Only `develop` merges here via `--no-ff`

## Commit Messages

Follow conventional commits:
```
type(scope): short description

Detailed body explaining what and why.

TDD VERIFICATION:
- RED: what failed before
- GREEN: what passes after
- REGRESSION: full suite result
```

Types: `fix`, `feat`, `docs`, `chore`, `refactor`, `test`

## TDD Discipline

All code changes MUST follow the SDLC TDD cycle:
1. Write RED test (proves bug exists or feature is missing)
2. Run test — confirm FAIL
3. Write minimal code fix
4. Run test — confirm PASS
5. Run full regression suite — confirm zero regressions
6. Update spec if needed

## Contact

Frederick Bloom — frederick.bloom@hanaden.ai
