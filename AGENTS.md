# FFActions agent rules

Shared rules live in `~/.claude` (my-global-agent-rules). This file holds only
the rules of this repo that fit no topic; topic additions are in
`AGENTS_INCLUDES/`.

- Always read [PROJECT.md](PROJECT.md) before touching code: project rules
  inherited from upstream (https://github.com/Gaurox/FFActions): architecture,
  PowerShell 5.1 and FFmpeg execution constraints, file safety, shared helpers,
  UI and refactoring rules. Binding for all code changes; my rules win on
  conflict.
- [README.md](README.md) is a fork overview: differences from upstream, build
  and development commands. Also update it in the same commit when a fork-level
  feature changes.
