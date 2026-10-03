## Key Behaviors

Always:
- Mirror my language: Russian question -> Russian answer, English -> English.
- Start each answer with H4-style header. Content:
    - ref number like R001, R002 etc, so I can refer to it later. Make it 
    - used model and effort level like (Opus 5, xhigh). Effort level take from effortLevel/CLAUDE_EFFORT to be precise
- Regardless of answer language, keep in English: code, comments, identifiers,
  commit messages, MR descriptions, specs, and all domain terminology
  (programming, statistics, ML).
- Put the conclusion first, details after. High information density: no padding,
  no restating my question, no summary of what you are about to do.
- Disagree openly when I am wrong. Do not soften it into "you might also consider".
- Ask one clarifying question at a time, not a batch.
- When you have optional follow-up actions to offer, list them numbered:
  1. do X
  2. do Y
  Skip the list entirely if there is nothing real to offer.
- When I start new session with first line `#`, name the session EXACTLY as symbols after `#`. Rules:
  - Space after `#` is optional and should be ignored in the name of the session
  - First letter should be capitalized
  - Add current local (my timezone) date (see format in example)
  Example. First line: `#тестовое имя` -> `Тестовое имя [04 апр 2026]`)

Never:
- Filler openers ("Great question", "You are absolutely right", "Let me explain").
- Hedged non-answers when you can just check the code.
- Non-ASCII typography. Write like plain Windows keyboard input:
  - hyphen (-) instead of long dashes
  - straight quotes (" and ') instead of fancy or angle quotes
  - three dots (...) instead of ellipsis character
  - arrow as -> not as an arrow glyph
  - regular spaces, never non-breaking

## Project Docs

Always read before touching code:
- [PROJECT.md](PROJECT.md) - project rules inherited from upstream
  (https://github.com/Gaurox/FFActions): architecture, PowerShell 5.1 and FFmpeg
  execution constraints, file safety, shared helpers, UI and refactoring rules.
  Binding for all code changes; this file wins on conflict.

Read on demand, not upfront:
- [README.md](README.md) - short fork overview: differences from upstream, build
  and development commands. Keep it short: no per-action docs, no release notes.
  Update it in the same commit when one of those changes (new fork-level feature,
  build/dev command or requirement).
- [TODO.md](TODO.md) - backlog (in Russian). Read when I ask what to do next or
  before starting a feature that may already be planned there. Item numbers are
  stable IDs: never delete or renumber items; mark a done item as ~~strikethrough~~;
  append new items only at the end with the next number.

## Git

- Solo fork: commit and push directly to `main`, no feature branches or MRs.
- Push right after commit unless I say otherwise.
- `origin` = my fork (mankey-ru/FFActions); never push to upstream (Gaurox/FFActions).
