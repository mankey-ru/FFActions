# FFActions (fork)

Personal fork of [Gaurox/FFActions](https://github.com/Gaurox/FFActions), based on upstream 1.4.1:
Windows Explorer right-click actions for video, audio and images, built on PowerShell 5.1 and FFmpeg.

## Differences from upstream

- Context menu is defined once in `dev/context_menu.psd1` and generated into the installer at compile time; items are grouped with separators
- `FFActionsDev` menu runs the actions straight from the working tree
- Generated `actions\*.ps1` run directly from the project, no exe build needed
- NVENC is detected with a real one-frame encode; fixed a silent crash after every FFmpeg run

## Build

Requires `tools\ffmpeg\ffmpeg.exe` and `ffprobe.exe` (not tracked) and the `ps2exe` module.

```powershell
.\build_all.ps1               # actions\*.ps1 and actions\*.exe
.\build_all.ps1 -ScriptsOnly  # scripts only
```

Installer: compile `FFActions.iss` with Inno Setup 6.

## Development

```powershell
.\dev\dev_menu.ps1              # register or refresh the FFActionsDev menu (HKCU)
.\dev\dev_menu.ps1 -Uninstall
powershell -ExecutionPolicy Bypass -STA -File .\actions\cut_video.ps1 "C:\path\video.mp4"
powershell -ExecutionPolicy Bypass -STA -File .\actions\convert_video.ps1 "C:\path\video.mkv" -ActionName convert_to_mp4
.\dev\smoke_test.ps1            # after build_all.ps1: non-UI actions, pickers, PDF runtime, dev menu
```

Project rules: [PROJECT.md](PROJECT.md). Backlog: [TODO.md](TODO.md).

## License

GPL-3.0, see [LICENSE](LICENSE).
