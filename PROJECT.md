# FFActions - Project Rules

> **Origin:** based on the original `AGENTS.md` from the upstream project
> https://github.com/Gaurox/FFActions (snapshot as of fork commit `fc9f682`,
> "Release 1.3.0"). This repo is a fork of it; the root `AGENTS.md` was replaced
> with personal working rules and links here.
>
> - Rules are kept as in upstream; only formatting was cleaned up and the
>   Architecture / Shared Helpers lists were synced with the current repo layout.
> - On conflict, root `AGENTS.md` wins over this file.
> - When syncing with upstream, check whether upstream `AGENTS.md` changed and
>   port the changes here.

## Description

- FFActions is a Windows tool using PowerShell 5.1 and FFmpeg.
- Each action is a standalone `.ps1` compiled to `.exe` (PS2EXE `-noConsole -STA`).
- Actions are triggered via Windows right-click context menu.
- All processing is local and offline.

## Architecture

- `actions/` -> action scripts (`*.template.ps1`)
- `actions/_shared/` -> shared helpers
- `actions/build_ffaction.ps1` -> builds individual actions
- `build_all.ps1` -> builds all actions
- `tools/` -> runtime files, mirrored to `{app}\tools` by the installer:
  `ffmpeg/` (`ffmpeg.exe` / `ffprobe.exe`), `icons/`, `pdf/`
- `dev/` -> developer tooling that is never shipped: context menu layout,
  installer menu generator, dev menu, smoke test (fork addition; keep scripts
  out of `tools/`)

## Core Principles

- Do NOT duplicate logic across scripts
- Always reuse shared helpers when available
- Keep each action script minimal and focused on its task
- Do NOT refactor multiple files unless explicitly asked
- Preserve existing behavior at all times

## PowerShell Constraints

- PowerShell 5.1 ONLY
- `param(...)` must be at the top of each script
- Do NOT use modern PowerShell features incompatible with 5.1
- Do NOT use `ArgumentList`
- Do NOT use `--%`
- Always handle paths with spaces correctly

## FFmpeg Execution Rules

- Must use `System.Diagnostics.Process`
- Required:
  - `UseShellExecute = false`
  - `CreateNoWindow = true`
  - `RedirectStandardOutput = true`
  - `RedirectStandardError = true`
- Arguments must be passed as a properly quoted string
- Never call ffmpeg directly in console mode

## File Safety

- NEVER overwrite existing files
- ALWAYS generate unique output names (suffix `_001`, `_002`, etc.)
- ALWAYS clean partial output files on failure

## Shared Helpers Usage

- `ffcommon_core.ps1`:
  - process execution
  - argument quoting
  - tool path resolution
  - unique output naming
  - error handling
- `ffcommon_progress.ps1`:
  - progress window
  - FFmpeg progress parsing
  - cancel handling
- `ffcommon_media.ps1`:
  - media info (duration, resolution, fps)
  - time parsing and formatting
- `ffcommon_picker.ps1`:
  - format selection UI
  - launching target actions
- `ffcommon_pdf.ps1`:
  - PDF runtime loading
  - image-to-PDF page layout, placement, crop, rotation
  - preview editor geometry and handles

## Rules for Shared Code

- Only place logic in `_shared` if:
  - used by multiple scripts
  - or critical to centralize (process, errors, naming)
- Shared functions may be:
  - strictly identical
  - or parameterized for reuse
- Do NOT move highly specific logic into shared files

## UI Guidelines

- Windows Forms only
- No console window
- Simple, stable UI
- Avoid flickering
- Reuse UI patterns when possible

## Refactoring Rules

- Refactor ONE file at a time unless explicitly asked
- Do NOT change architecture
- Do NOT introduce new dependencies
- Do NOT break compatibility with existing build system
- Prefer small, safe improvements

## When Implementing New Features

- Always check if shared helpers already provide the needed logic
- Reuse existing patterns (convert, extract, resize, etc.)
- Do NOT rewrite process or FFmpeg logic
- Keep consistency with existing scripts

## Expected Behavior

All actions must:

- run silently (no console)
- handle errors cleanly
- generate valid output files
- be robust with all input paths
