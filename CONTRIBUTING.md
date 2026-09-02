<!-- (c) 2026-* Frederick Bloom -- CONTRIBUTING.md -- Hanaden AI -->

# Contributing to bwrap-enhanced

## License

All contributions are governed by the project [`LICENSE.md`](LICENSE.md) and require
prior execution of the [`CLA`](PROJECT_HOME/docs/legal/FrederickBloom/CLA.md).

## Branch Workflow

This project follows a two-tier branch model:

```
feature/* → master
```

1. **feature/*** — All work happens on feature branches created from `master`
2. **master** — Release branch. Feature branches merge here via `--no-ff` only when
   all tests pass at 100% and all specs are satisfied.

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

```bash
./PROJECT_HOME/src/test/hanaden-bwrap-enhanced/run_phase1.sh
```

## Contact

Frederick Bloom — devlabs@hanaden.com

## Documentation

Full project documentation: https://hanasaki.github.io/hanaden-bwrap-enhanced/site/
