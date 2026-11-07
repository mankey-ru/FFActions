# Git rules (FFActions)

- Solo fork: commit and push directly to `main`, no feature branches or MRs.
- `origin` = my fork (mankey-ru/FFActions); never push to upstream
  (Gaurox/FFActions).
- Smoke test: run it before every push and when I ask, not before each commit.
  Use `.\dev\smoke_test.ps1 -Changed`: it picks the checks from the diff against
  `origin/main` and fails builds older than their changed sources. Before it, run
  `.\build_all.ps1` when `actions/` changed and `.\dev\dev_menu.ps1` when the menu
  layout changed. Push only on a green run, otherwise report the failing checks.
  Always state what the run did not cover (it prints "Not covered": interactive
  actions, installer compile). Pushes without such changes need no run.
