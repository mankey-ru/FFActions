param(
    # Which build output to exercise: compiled exes, generated scripts, or both.
    [ValidateSet('All', 'Exe', 'Script')]
    [string]$Mode = 'All',
    # Skip the picker chains: they open picker windows and click a format button.
    [switch]$SkipPickers
)

# Smoke test for the built actions (run build_all.ps1 first):
#   - generated scripts parse
#   - non-interactive actions on generated media, as exes and as generated scripts
#   - format pickers driven through UI Automation: picker -> target action -> output
#   - PDF runtime: exe with image_to_pdf.exe.config only, script with the assembly resolver
#   - FFActionsDev menu as Explorer builds it, against dev\context_menu.psd1
# Interactive actions (cut, crop, resize, ...) are not covered.
# Work files go to test\smoke (ignored, recreated on every run).
# Exit code: number of failed checks.

$windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
if ($PSVersionTable.PSEdition -ne 'Desktop' -or [System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    # The actions target Windows PowerShell 5.1, and the shell menu probe needs STA.
    $relaunch = @('-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, '-Mode', $Mode)
    if ($SkipPickers) {
        $relaunch += '-SkipPickers'
    }

    & $windowsPowerShell @relaunch
    exit $LASTEXITCODE
}

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$actionsDir = Join-Path $repoRoot 'actions'
$ffmpegPath = Join-Path $repoRoot 'tools\ffmpeg\ffmpeg.exe'
$workRoot = Join-Path $repoRoot 'test\smoke'
$mediaDir = Join-Path $workRoot 'media'
$devMenuName = 'FFActionsDev'
$timeoutSeconds = 120

$runModes = switch ($Mode) {
    'All' { @('exe', 'script') }
    'Exe' { @('exe') }
    'Script' { @('script') }
}

. (Join-Path $actionsDir '_shared\ffcommon_core.ps1')
. (Join-Path $PSScriptRoot 'context_menu_layout.ps1')

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

namespace FFActionsSmoke {
    [ComImport, Guid("000214E6-0000-0000-C000-000000000046"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IShellFolder {
        void ParseDisplayName(); void EnumObjects(); void BindToObject(); void BindToStorage();
        void CompareIDs(); void CreateViewObject(); void GetAttributesOf();
        [PreserveSig] int GetUIObjectOf(IntPtr hwnd, uint cidl, [In, MarshalAs(UnmanagedType.LPArray)] IntPtr[] apidl, ref Guid riid, IntPtr rgf, out IntPtr ppv);
    }

    [ComImport, Guid("000214F4-0000-0000-C000-000000000046"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IContextMenu2 {
        [PreserveSig] int QueryContextMenu(IntPtr hmenu, uint indexMenu, uint idCmdFirst, uint idCmdLast, uint uFlags);
        void InvokeCommand(); void GetCommandString();
        [PreserveSig] int HandleMenuMsg(uint uMsg, IntPtr wParam, IntPtr lParam);
    }

    public static class Native {
        [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);
        [DllImport("user32.dll")] internal static extern IntPtr CreatePopupMenu();
        [DllImport("user32.dll")] internal static extern bool DestroyMenu(IntPtr hMenu);
        [DllImport("user32.dll")] internal static extern int GetMenuItemCount(IntPtr hMenu);
        [DllImport("user32.dll")] internal static extern IntPtr GetSubMenu(IntPtr hMenu, int pos);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] internal static extern int GetMenuString(IntPtr hMenu, uint id, StringBuilder text, int max, uint flags);
        [DllImport("shell32.dll", CharSet = CharSet.Unicode)] internal static extern int SHParseDisplayName(string name, IntPtr bindCtx, out IntPtr pidl, uint sfgaoIn, out uint sfgaoOut);
        [DllImport("shell32.dll")] internal static extern int SHBindToParent(IntPtr pidl, ref Guid riid, out IntPtr ppv, out IntPtr ppidlLast);
    }

    // Items of a cascading context menu entry exactly as Explorer builds them
    // ("----" for separators), or null when the file has no such entry.
    public static class ShellMenu {
        const uint MF_BYPOSITION = 0x400;
        const uint WM_INITMENUPOPUP = 0x117;

        public static string[] GetSubmenuItems(string path, string entryText) {
            IntPtr pidl; uint attributes;
            Marshal.ThrowExceptionForHR(Native.SHParseDisplayName(path, IntPtr.Zero, out pidl, 0, out attributes));
            try {
                Guid folderId = typeof(IShellFolder).GUID;
                IntPtr folderPtr, child;
                Marshal.ThrowExceptionForHR(Native.SHBindToParent(pidl, ref folderId, out folderPtr, out child));
                IShellFolder folder = (IShellFolder)Marshal.GetObjectForIUnknown(folderPtr);
                Marshal.Release(folderPtr);

                Guid menuId = new Guid("000214E4-0000-0000-C000-000000000046");
                IntPtr menuPtr;
                Marshal.ThrowExceptionForHR(folder.GetUIObjectOf(IntPtr.Zero, 1, new IntPtr[] { child }, ref menuId, IntPtr.Zero, out menuPtr));
                IContextMenu2 menu = (IContextMenu2)Marshal.GetObjectForIUnknown(menuPtr);
                Marshal.Release(menuPtr);

                IntPtr hmenu = Native.CreatePopupMenu();
                try {
                    menu.QueryContextMenu(hmenu, 0, 1, 0x7FFF, 0);
                    int count = Native.GetMenuItemCount(hmenu);
                    for (int i = 0; i < count; i++) {
                        if (GetText(hmenu, i) != entryText) continue;

                        IntPtr sub = Native.GetSubMenu(hmenu, i);
                        if (sub == IntPtr.Zero) return new string[0];

                        // static submenus are filled lazily, like when Explorer opens them
                        menu.HandleMenuMsg(WM_INITMENUPOPUP, sub, (IntPtr)i);
                        List<string> items = new List<string>();
                        int subCount = Native.GetMenuItemCount(sub);
                        for (int j = 0; j < subCount; j++) {
                            string text = GetText(sub, j);
                            items.Add(text.Length > 0 ? text : "----");
                        }
                        return items.ToArray();
                    }
                    return null;
                }
                finally {
                    Native.DestroyMenu(hmenu);
                }
            }
            finally {
                Marshal.FreeCoTaskMem(pidl);
            }
        }

        static string GetText(IntPtr hmenu, int position) {
            StringBuilder text = new StringBuilder(256);
            Native.GetMenuString(hmenu, (uint)position, text, text.Capacity, MF_BYPOSITION);
            return text.ToString();
        }
    }
}
'@

$results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
    param(
        [string]$Check,
        [string]$RunMode,
        [ValidateSet('PASS', 'FAIL', 'SKIP')][string]$Status,
        [string]$Detail = ''
    )

    $results.Add([PSCustomObject]@{ Check = $Check; Mode = $RunMode; Status = $Status; Detail = $Detail })
    $color = @{ PASS = 'Green'; FAIL = 'Red'; SKIP = 'Yellow' }[$Status]
    Write-Host ('{0,-4}  {1,-6}  {2,-28}  {3}' -f $Status, $RunMode, $Check, $Detail) -ForegroundColor $color
}

function Invoke-FFmpeg {
    param([string[]]$Arguments)

    & $ffmpegPath -hide_banner -loglevel error -y @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "ffmpeg failed: $($Arguments -join ' ')"
    }
}

function Get-ActionFile {
    param([string]$RunMode, [string]$Name)

    $extension = if ($RunMode -eq 'exe') { '.exe' } else { '.ps1' }
    return Join-Path $actionsDir ($Name + $extension)
}

# Starts an action the way Explorer does (exe) or as the generated script; the
# multi-exe families get -ActionName when run as a script.
function Start-Action {
    param([string]$RunMode, [string]$ActionName, [string]$ScriptName, [string[]]$Arguments)

    if ($RunMode -eq 'exe') {
        $filePath = Get-ActionFile -RunMode 'exe' -Name $ActionName
        $argumentList = Join-ProcessArguments -Arguments $Arguments
    }
    else {
        $filePath = $windowsPowerShell
        $hostArguments = @('-NoProfile', '-STA', '-WindowStyle', 'Hidden', '-ExecutionPolicy', 'Bypass',
            '-File', (Get-ActionFile -RunMode 'script' -Name $ScriptName)) + $Arguments
        if ($ActionName -ne $ScriptName) {
            $hostArguments += @('-ActionName', $ActionName)
        }

        $argumentList = Join-ProcessArguments -Arguments $hostArguments
    }

    $process = Start-Process -FilePath $filePath -ArgumentList $argumentList -PassThru
    $null = $process.Handle  # keeps ExitCode readable after the process exits
    return $process
}

# Live processes of the tree: the root and everything it started, including children
# of already exited parents (a picker exits right after starting its target). One
# snapshot answers both "who is a child" and "who is alive": a target is created
# before its picker exits, so a snapshot never misses both.
function Get-ProcessTreeIds {
    param([int]$RootId)

    $snapshot = @(Get-CimInstance -ClassName Win32_Process -Property ProcessId, ParentProcessId)
    $ids = [System.Collections.Generic.List[int]]::new()
    $ids.Add($RootId)
    for ($i = 0; $i -lt $ids.Count; $i++) {
        foreach ($candidate in $snapshot) {
            if ($candidate.ParentProcessId -eq $ids[$i] -and -not $ids.Contains([int]$candidate.ProcessId)) {
                $ids.Add([int]$candidate.ProcessId)
            }
        }
    }

    $alive = @($snapshot | ForEach-Object { [int]$_.ProcessId })
    return @($ids | Where-Object { $alive -contains $_ })
}

function Get-WindowText {
    param([int[]]$ProcessIds)

    $texts = foreach ($id in $ProcessIds) {
        $condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, $id)
        foreach ($window in [System.Windows.Automation.AutomationElement]::RootElement.FindAll([System.Windows.Automation.TreeScope]::Children, $condition)) {
            $names = @($window.Current.Name)
            foreach ($element in $window.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)) {
                if ($element.Current.Name -and $element.Current.Name -notin 'OK', 'Cancel') {
                    $names += $element.Current.Name
                }
            }

            ($names | Where-Object { $_ }) -join ': '
        }
    }

    return (@($texts | Where-Object { $_ }) -join ' | ') -replace '\s+', ' '
}

# Waits for the whole process tree to finish. On timeout returns the text of its
# windows (normally an error dialog) and kills it; returns $null on success.
function Wait-ProcessTree {
    param([int]$RootId)

    $deadline = (Get-Date).AddSeconds($timeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (@(Get-ProcessTreeIds -RootId $RootId).Count -eq 0) {
            return $null
        }

        Start-Sleep -Milliseconds 500
    }

    $alive = @(Get-ProcessTreeIds -RootId $RootId)
    $text = Get-WindowText -ProcessIds $alive
    foreach ($id in $alive) {
        Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
    }

    return "no exit in ${timeoutSeconds}s, windows: $text"
}

# Copies the input into a fresh folder per check, so the output is whatever appears next to it.
function New-CaseFolder {
    param([string]$Name, [string]$InputName)

    $folder = Join-Path $workRoot $Name
    New-Item -ItemType Directory -Path $folder | Out-Null
    Copy-Item -LiteralPath (Join-Path $mediaDir $InputName) -Destination $folder
    return $folder
}

function Get-NewOutput {
    param([string]$Folder, [string]$InputName, [string]$Pattern)

    foreach ($item in Get-ChildItem -LiteralPath $Folder -Filter $Pattern) {
        if ($item.Name -eq $InputName) {
            continue
        }

        if ($item.PSIsContainer) {
            $count = @(Get-ChildItem -LiteralPath $item.FullName -File).Count
            if ($count -gt 0) {
                '{0}\ ({1} files)' -f $item.Name, $count
            }
        }
        elseif ($item.Length -gt 0) {
            '{0} ({1} B)' -f $item.Name, $item.Length
        }
    }
}

function Test-ActionCase {
    param($Case, [string]$RunMode)

    $name = if ($RunMode -eq 'exe') { $Case.Action } else { $Case.Script }
    $actionFile = Get-ActionFile -RunMode $RunMode -Name $name
    if (-not (Test-Path -LiteralPath $actionFile)) {
        Add-Result $Case.Action $RunMode 'FAIL' "missing $actionFile (run build_all.ps1)"
        return
    }

    $folder = New-CaseFolder -Name "$RunMode-$($Case.Action)" -InputName $Case.Input
    $process = Start-Action -RunMode $RunMode -ActionName $Case.Action -ScriptName $Case.Script `
        -Arguments (@(Join-Path $folder $Case.Input) + $Case.Extra)
    $timeout = Wait-ProcessTree -RootId $process.Id
    $output = @(Get-NewOutput -Folder $folder -InputName $Case.Input -Pattern $Case.Output)

    if ($timeout) {
        Add-Result $Case.Action $RunMode 'FAIL' $timeout
    }
    elseif ($process.ExitCode -ne 0 -or $output.Count -eq 0) {
        Add-Result $Case.Action $RunMode 'FAIL' ("exit code {0}, output: {1}" -f $process.ExitCode, ($output -join ', '))
    }
    else {
        Add-Result $Case.Action $RunMode 'PASS' ($output -join ', ')
    }
}

function Wait-PickerWindow {
    param([int]$ProcessId)

    $condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, $ProcessId)
    $deadline = (Get-Date).AddSeconds(30)
    while ((Get-Date) -lt $deadline) {
        foreach ($window in [System.Windows.Automation.AutomationElement]::RootElement.FindAll([System.Windows.Automation.TreeScope]::Children, $condition)) {
            if ($window.Current.Name -like 'FFActions*') {
                return $window
            }
        }

        Start-Sleep -Milliseconds 250
    }

    return $null
}

function Test-PickerCase {
    param($Case, [string]$RunMode)

    $check = "$($Case.Picker) $($Case.Button)"
    $pickerFile = Get-ActionFile -RunMode $RunMode -Name $Case.Picker
    if (-not (Test-Path -LiteralPath $pickerFile)) {
        Add-Result $check $RunMode 'FAIL' "missing $pickerFile (run build_all.ps1)"
        return
    }

    $folder = New-CaseFolder -Name "$RunMode-$($Case.Picker)" -InputName $Case.Input
    $process = Start-Action -RunMode $RunMode -ActionName $Case.Picker -ScriptName $Case.Picker -Arguments @(Join-Path $folder $Case.Input)

    $window = Wait-PickerWindow -ProcessId $process.Id
    $nameCondition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $Case.Button)
    $button = if ($window) { $window.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $nameCondition) } else { $null }
    if ($null -eq $button) {
        $alive = @(Get-ProcessTreeIds -RootId $process.Id)
        $text = Get-WindowText -ProcessIds $alive
        foreach ($id in $alive) {
            Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
        }

        Add-Result $check $RunMode 'FAIL' "no '$($Case.Button)' button, windows: $text"
        return
    }

    # BM_CLICK: WinForms buttons show up in UI Automation as Pane without InvokePattern
    [void][FFActionsSmoke.Native]::PostMessage([IntPtr]$button.Current.NativeWindowHandle, 0x00F5, [IntPtr]::Zero, [IntPtr]::Zero)
    $timeout = Wait-ProcessTree -RootId $process.Id
    $output = @(Get-NewOutput -Folder $folder -InputName $Case.Input -Pattern $Case.Output)

    if ($timeout) {
        Add-Result $check $RunMode 'FAIL' $timeout
    }
    elseif ($output.Count -eq 0) {
        Add-Result $check $RunMode 'FAIL' 'no output'
    }
    else {
        Add-Result $check $RunMode 'PASS' ($output -join ', ')
    }
}

# Converts an image with the shared PDF code from a probe of its own. The exe probe
# stubs out the assembly resolver, so it passes only if image_to_pdf.exe.config
# supplies the binding redirects; the script probe has no config and needs the resolver.
function Test-PdfRuntime {
    param([string]$RunMode)

    $folder = Join-Path $workRoot "$RunMode-pdf"
    New-Item -ItemType Directory -Path $folder | Out-Null
    $resultFile = Join-Path $folder 'result.txt'
    $pdfFile = Join-Path $folder 'frame.pdf'
    $resolverStub = if ($RunMode -eq 'exe') { 'function Register-PdfRuntimeResolver { param($PdfDirectory) }' } else { '' }

    $probe = @"
function Get-PdfAppRoot { return '$repoRoot' }
$resolverStub
Add-Type -AssemblyName System.Drawing
. '$(Join-Path $actionsDir '_shared\ffcommon_pdf.ps1')'
try {
    Import-PdfRuntime
    Convert-ImageFileToPdf -InputFile '$(Join-Path $mediaDir 'frame.png')' -OutputFile '$pdfFile'
    [System.IO.File]::WriteAllText('$resultFile', ('OK ' + (Get-Item -LiteralPath '$pdfFile').Length + ' B'))
}
catch {
    [System.IO.File]::WriteAllText('$resultFile', ('FAIL ' + `$_.Exception.Message))
}
"@
    $probeScript = Join-Path $folder 'pdf_probe.ps1'
    [System.IO.File]::WriteAllText($probeScript, $probe, (New-Object System.Text.UTF8Encoding($false)))

    if ($RunMode -eq 'exe') {
        $config = Join-Path $actionsDir 'image_to_pdf.exe.config'
        if (-not (Test-Path -LiteralPath $config)) {
            Add-Result 'pdf runtime' $RunMode 'FAIL' "missing $config"
            return
        }

        if (-not (Get-Module -ListAvailable -Name ps2exe)) {
            Add-Result 'pdf runtime' $RunMode 'SKIP' 'ps2exe module not installed'
            return
        }

        $probeExe = Join-Path $folder 'pdf_probe.exe'
        try {
            Invoke-PS2EXE -inputFile $probeScript -outputFile $probeExe -noConsole -STA *> $null
        }
        catch {
            Add-Result 'pdf runtime' $RunMode 'FAIL' "ps2exe failed: $($_.Exception.Message)"
            return
        }

        Copy-Item -LiteralPath $config -Destination "$probeExe.config"
        $process = Start-Process -FilePath $probeExe -PassThru
    }
    else {
        $process = Start-Process -FilePath $windowsPowerShell -PassThru -ArgumentList (Join-ProcessArguments -Arguments @(
            '-NoProfile', '-STA', '-WindowStyle', 'Hidden', '-ExecutionPolicy', 'Bypass', '-File', $probeScript))
    }

    $timeout = Wait-ProcessTree -RootId $process.Id
    $result = if (Test-Path -LiteralPath $resultFile) { [System.IO.File]::ReadAllText($resultFile) } else { 'no result' }
    if ($timeout) {
        Add-Result 'pdf runtime' $RunMode 'FAIL' $timeout
    }
    elseif ($result.StartsWith('OK')) {
        Add-Result 'pdf runtime' $RunMode 'PASS' $result
    }
    else {
        Add-Result 'pdf runtime' $RunMode 'FAIL' $result
    }
}

# Expected FFActionsDev items for one extension: every layout entry is registered,
# separators follow the same per-extension rule as dev_menu.ps1 and the installer.
function Get-ExpectedMenuItems {
    param([object[]]$Entries, [string]$Extension)

    $tracker = New-ContextMenuSeparatorTracker
    foreach ($entry in $Entries) {
        Enter-ContextMenuEntry -Tracker $tracker -Entry $entry
        if ($entry.Extensions -notcontains $Extension) {
            continue
        }

        if (Get-ContextMenuItemFlags -Tracker $tracker -Extension $Extension) {
            '----'
        }

        $entry.Label
    }
}

function Test-DevMenu {
    $entries = Get-ContextMenuEntries
    $samples = @(
        @{ Extension = '.mp4'; File = Join-Path $mediaDir 'clip.mp4' }
        @{ Extension = '.wav'; File = Join-Path $mediaDir 'clip.wav' }
        @{ Extension = '.png'; File = Join-Path $mediaDir 'frame.png' }
        @{ Extension = '.webp'; File = Join-Path $mediaDir 'empty.webp' }
    )

    foreach ($sample in $samples) {
        $check = "menu $($sample.Extension)"
        $expected = @(Get-ExpectedMenuItems -Entries $entries -Extension $sample.Extension) -join ' | '
        $items = [FFActionsSmoke.ShellMenu]::GetSubmenuItems($sample.File, $devMenuName)
        if ($null -eq $items) {
            Add-Result $check 'menu' 'FAIL' "no $devMenuName entry (run dev\dev_menu.ps1)"
            continue
        }

        $actual = $items -join ' | '
        if ($actual -eq $expected) {
            Add-Result $check 'menu' 'PASS' "$($items.Count) items"
        }
        else {
            Add-Result $check 'menu' 'FAIL' "expected [$expected], got [$actual] (re-run dev\dev_menu.ps1?)"
        }
    }

    $commands = @(Get-ChildItem -Path 'HKCU:\Software\Classes\SystemFileAssociations' -ErrorAction SilentlyContinue | ForEach-Object {
        $verbs = Join-Path $_.PSPath "shell\$devMenuName\shell"
        if (Test-Path -LiteralPath $verbs) {
            Get-ChildItem -LiteralPath $verbs | ForEach-Object { (Get-ItemProperty -LiteralPath (Join-Path $_.PSPath 'command')).'(default)' }
        }
    })
    $missing = @($commands | ForEach-Object { ($_ -split '"')[1] } | Sort-Object -Unique | Where-Object { -not (Test-Path -LiteralPath $_) })
    if ($commands.Count -eq 0) {
        Add-Result 'menu commands' 'menu' 'FAIL' "no $devMenuName commands registered"
    }
    elseif ($missing.Count -gt 0) {
        Add-Result 'menu commands' 'menu' 'FAIL' ('missing: ' + ($missing -join ', '))
    }
    else {
        Add-Result 'menu commands' 'menu' 'PASS' "$($commands.Count) commands point to existing files"
    }
}

if (-not (Test-Path -LiteralPath $ffmpegPath)) {
    throw "ffmpeg not found: $ffmpegPath"
}

if (Test-Path -LiteralPath $workRoot) {
    Remove-Item -LiteralPath $workRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $mediaDir | Out-Null
Invoke-FFmpeg @('-f', 'lavfi', '-i', 'testsrc2=duration=3:size=320x240:rate=25', '-f', 'lavfi', '-i', 'sine=frequency=440:duration=3',
    '-c:v', 'libx264', '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-shortest', (Join-Path $mediaDir 'clip.mp4'))
Invoke-FFmpeg @('-f', 'lavfi', '-i', 'sine=frequency=440:duration=3', (Join-Path $mediaDir 'clip.wav'))
Invoke-FFmpeg @('-f', 'lavfi', '-i', 'testsrc2=size=320x240', '-frames:v', '1', (Join-Path $mediaDir 'frame.png'))
[System.IO.File]::WriteAllBytes((Join-Path $mediaDir 'empty.webp'), [byte[]]@())

$parseErrors = foreach ($script in Get-ChildItem -LiteralPath $actionsDir -Filter '*.ps1' | Where-Object { $_.Name -notlike '*.template.ps1' }) {
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$null, [ref]$errors)
    if ($errors.Count -gt 0) {
        '{0}: {1}' -f $script.Name, $errors[0].Message
    }
}
if ($parseErrors) {
    Add-Result 'scripts parse' 'script' 'FAIL' (@($parseErrors) -join '; ')
}
else {
    Add-Result 'scripts parse' 'script' 'PASS'
}

$actionCases = @(
    @{ Action = 'remove_audio';          Script = 'remove_audio';   Input = 'clip.mp4';  Output = '*.mp4';     Extra = @() }
    @{ Action = 'reverse_audio';         Script = 'reverse_audio';  Input = 'clip.wav';  Output = '*.wav';     Extra = @() }
    @{ Action = 'extract_frames';        Script = 'extract_frames'; Input = 'clip.mp4';  Output = '*_frames*'; Extra = @() }
    @{ Action = 'extract_audio_to_mp3';  Script = 'extract_audio';  Input = 'clip.mp4';  Output = '*.mp3';     Extra = @() }
    @{ Action = 'convert_audio_to_flac'; Script = 'convert_audio';  Input = 'clip.wav';  Output = '*.flac';    Extra = @() }
    @{ Action = 'convert_image_to_jpg';  Script = 'convert_image';  Input = 'frame.png'; Output = '*.jpg';     Extra = @() }
    @{ Action = 'convert_to_mkv';        Script = 'convert_video';  Input = 'clip.mp4';  Output = '*.mkv';     Extra = @('universal') }
)

$pickerCases = @(
    @{ Picker = 'extract_audio_picker'; Input = 'clip.mp4';  Button = 'WAV'; Output = '*.wav' }
    @{ Picker = 'convert_video_picker'; Input = 'clip.mp4';  Button = 'MOV'; Output = '*.mov' }
    @{ Picker = 'convert_audio_picker'; Input = 'clip.wav';  Button = 'MP3'; Output = '*.mp3' }
    @{ Picker = 'convert_image_picker'; Input = 'frame.png'; Button = 'BMP'; Output = '*.bmp' }
)

foreach ($runMode in $runModes) {
    foreach ($case in $actionCases) {
        Test-ActionCase -Case $case -RunMode $runMode
    }

    foreach ($case in $pickerCases) {
        if ($SkipPickers) {
            Add-Result "$($case.Picker) $($case.Button)" $runMode 'SKIP' '-SkipPickers'
        }
        else {
            Test-PickerCase -Case $case -RunMode $runMode
        }
    }

    Test-PdfRuntime -RunMode $runMode
}

Test-DevMenu

$failed = @($results | Where-Object Status -eq 'FAIL').Count
$skipped = @($results | Where-Object Status -eq 'SKIP').Count
Write-Host ''
Write-Host ('{0} checks: {1} passed, {2} failed, {3} skipped. Work files: {4}' -f $results.Count, ($results.Count - $failed - $skipped), $failed, $skipped, $workRoot)
exit $failed
