param(
    # Which build output to exercise: compiled exes, generated scripts, or both.
    [ValidateSet('All', 'Exe', 'Script')]
    [string]$Mode = 'All',
    # Skip the picker chains: they open picker windows and click a format button.
    [switch]$SkipPickers,
    # Skip the cut dialogs: they open the action window, fill in a prefix and confirm.
    [switch]$SkipDialogs,
    # Run only the checks that cover files changed since -Base (commits and uncommitted work).
    [switch]$Changed,
    # Base for -Changed: the diff starts at the merge base of -Base and HEAD.
    [string]$Base = 'origin/main'
)

# Smoke test for the built actions (run build_all.ps1 first):
#   - generated scripts parse
#   - non-interactive actions on generated media, as exes and as generated scripts
#   - format pickers driven through UI Automation: picker -> target action -> output
#   - cut video / cut audio dialogs: filename prefix with invalid characters -> confirm -> output
#   - PDF runtime: exe with image_to_pdf.exe.config only, script with the assembly resolver
#   - FFActionsDev menu as Explorer builds it, against dev\context_menu.psd1
# Other interactive actions (crop, resize, ...) are not covered.
# -Changed picks the checks from the changed files, fails builds older than their
# changed sources and lists what nothing covers (interactive actions, installer).
# Work files go to test\smoke (ignored, recreated on every run).
# Exit code: number of failed checks.

$windowsPowerShell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
if ($PSVersionTable.PSEdition -ne 'Desktop' -or [System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    # The actions target Windows PowerShell 5.1, and the shell menu probe needs STA.
    $relaunch = @('-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath, '-Mode', $Mode)
    if ($SkipPickers) {
        $relaunch += '-SkipPickers'
    }

    if ($SkipDialogs) {
        $relaunch += '-SkipDialogs'
    }

    if ($Changed) {
        $relaunch += @('-Changed', '-Base', $Base)
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
$selection = $null  # -Changed: what to run, see Get-ChangedSelection

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
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, string lParam);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr SendMessage(IntPtr hWnd, uint msg, IntPtr wParam, StringBuilder lParam);
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

# With -Changed, a build older than its own changed sources (its templates, shared
# helpers, build scripts) would test the old code.
function Get-StaleNote {
    param([string]$Path, [string[]]$Scripts)

    if ($null -eq $selection) {
        return $null
    }

    $patterns = @('^actions/_shared/', '^actions/build_ffaction\.ps1$', '^build_all\.ps1$') +
        @($Scripts | ForEach-Object { '^actions/' + [regex]::Escape($_) + '\.template\.ps1$' })
    $newest = $selection.Files |
        Where-Object { $file = $_; @($patterns | Where-Object { $file -match $_ }).Count -gt 0 } |
        ForEach-Object { Join-Path $repoRoot $_ } | Where-Object { Test-Path -LiteralPath $_ } |
        ForEach-Object { (Get-Item -LiteralPath $_).LastWriteTime } | Sort-Object -Descending | Select-Object -First 1

    if ($newest -and (Get-Item -LiteralPath $Path).LastWriteTime -lt $newest) {
        return "$(Split-Path -Leaf $Path) is older than its changed sources (run build_all.ps1)"
    }

    return $null
}

function Test-ActionCase {
    param($Case, [string]$RunMode)

    $name = if ($RunMode -eq 'exe') { $Case.Action } else { $Case.Script }
    $actionFile = Get-ActionFile -RunMode $RunMode -Name $name
    if (-not (Test-Path -LiteralPath $actionFile)) {
        Add-Result $Case.Action $RunMode 'FAIL' "missing $actionFile (run build_all.ps1)"
        return
    }

    $stale = Get-StaleNote -Path $actionFile -Scripts @($Case.Script)
    if ($stale) {
        Add-Result $Case.Action $RunMode 'FAIL' $stale
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

function Wait-ActionWindow {
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

    $stale = Get-StaleNote -Path $pickerFile -Scripts @($Case.Picker, $Case.Target)
    if ($stale) {
        Add-Result $check $RunMode 'FAIL' $stale
        return
    }

    $folder = New-CaseFolder -Name "$RunMode-$($Case.Picker)" -InputName $Case.Input
    $process = Start-Action -RunMode $RunMode -ActionName $Case.Picker -ScriptName $Case.Picker -Arguments @(Join-Path $folder $Case.Input)

    $window = Wait-ActionWindow -ProcessId $process.Id
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

# Types the prefix into the topmost text field of the dialog (the filename prefix) with
# WM_SETTEXT, which raises TextChanged like typing does, then clicks the confirm button.
# The field must show the invalid characters replaced and the output must carry the prefix.
function Test-DialogCase {
    param($Case, [string]$RunMode)

    $check = "$($Case.Script) dialog"
    $actionFile = Get-ActionFile -RunMode $RunMode -Name $Case.Script
    if (-not (Test-Path -LiteralPath $actionFile)) {
        Add-Result $check $RunMode 'FAIL' "missing $actionFile (run build_all.ps1)"
        return
    }

    $stale = Get-StaleNote -Path $actionFile -Scripts @($Case.Script)
    if ($stale) {
        Add-Result $check $RunMode 'FAIL' $stale
        return
    }

    $folder = New-CaseFolder -Name "$RunMode-$($Case.Script)" -InputName $Case.Input
    $process = Start-Action -RunMode $RunMode -ActionName $Case.Script -ScriptName $Case.Script -Arguments @(Join-Path $folder $Case.Input)

    $window = Wait-ActionWindow -ProcessId $process.Id
    $field = $null
    $button = $null
    if ($window) {
        # WinForms controls show up in UI Automation as Pane; the window class tells a TextBox
        $elements = @($window.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition))
        $field = $elements | Where-Object { $_.Current.ClassName -like '*.EDIT.*' } |
            Sort-Object { $_.Current.BoundingRectangle.Y }, { $_.Current.BoundingRectangle.X } | Select-Object -First 1
        $button = $elements | Where-Object { $_.Current.ClassName -like '*.BUTTON.*' -and $_.Current.Name -eq $Case.Button } | Select-Object -First 1
    }

    if ($null -eq $field -or $null -eq $button) {
        $alive = @(Get-ProcessTreeIds -RootId $process.Id)
        $text = Get-WindowText -ProcessIds $alive
        foreach ($id in $alive) {
            Stop-Process -Id $id -Force -ErrorAction SilentlyContinue
        }

        Add-Result $check $RunMode 'FAIL' "no prefix field or '$($Case.Button)' button, windows: $text"
        return
    }

    $fieldHandle = [IntPtr]$field.Current.NativeWindowHandle
    [void][FFActionsSmoke.Native]::SendMessage($fieldHandle, 0x000C, [IntPtr]::Zero, $dialogPrefixInput)  # WM_SETTEXT
    $fieldText = New-Object System.Text.StringBuilder 256
    [void][FFActionsSmoke.Native]::SendMessage($fieldHandle, 0x000D, [IntPtr]$fieldText.Capacity, $fieldText)  # WM_GETTEXT

    [void][FFActionsSmoke.Native]::PostMessage([IntPtr]$button.Current.NativeWindowHandle, 0x00F5, [IntPtr]::Zero, [IntPtr]::Zero)  # BM_CLICK
    $timeout = Wait-ProcessTree -RootId $process.Id
    $output = @(Get-NewOutput -Folder $folder -InputName $Case.Input -Pattern '*')
    $expected = @(Get-NewOutput -Folder $folder -InputName $Case.Input -Pattern $Case.Output)

    if ($timeout) {
        Add-Result $check $RunMode 'FAIL' $timeout
    }
    elseif ($fieldText.ToString() -cne $dialogPrefixField) {
        Add-Result $check $RunMode 'FAIL' ("prefix field shows '{0}', expected '{1}'" -f $fieldText, $dialogPrefixField)
    }
    elseif ($process.ExitCode -ne 0 -or $expected.Count -eq 0) {
        Add-Result $check $RunMode 'FAIL' ("exit code {0}, expected {1}, output: {2}" -f $process.ExitCode, $Case.Output, ($output -join ', '))
    }
    else {
        Add-Result $check $RunMode 'PASS' ($expected -join ', ')
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

# -Changed: maps the files changed since the merge base of $Base and HEAD (commits,
# uncommitted and untracked files) to the checks that cover them.
function Get-ChangedSelection {
    $mergeBase = & git -C $repoRoot merge-base $Base HEAD
    if ($LASTEXITCODE -ne 0) {
        throw "Cannot find the merge base of $Base and HEAD."
    }

    $files = @(& git -C $repoRoot diff --name-only $mergeBase) + @(& git -C $repoRoot ls-files --others --exclude-standard)
    $result = @{
        MergeBase  = $mergeBase
        Files      = @($files | Where-Object { $_ } | Sort-Object -Unique)
        All        = $false
        Scripts    = [System.Collections.Generic.HashSet[string]]::new()
        Pdf        = $false
        Menu       = $false
        NotCovered = [System.Collections.Generic.List[string]]::new()
    }

    $coveredScripts = @($actionCases | ForEach-Object { $_.Script }) + @($pickerCases | ForEach-Object { $_.Picker; $_.Target }) +
        @($dialogCases | ForEach-Object { $_.Script })
    foreach ($file in $result.Files) {
        switch -Regex ($file) {
            '^(build_all\.ps1|actions/build_ffaction\.ps1|actions/_shared/ffcommon_(core|progress|media)\.ps1|dev/smoke_test\.ps1)$' {
                $result.All = $true
                break
            }
            '^actions/_shared/ffcommon_picker\.ps1$' {
                foreach ($case in $pickerCases) {
                    [void]$result.Scripts.Add($case.Picker)
                }
                break
            }
            '^(actions/_shared/ffcommon_pdf\.ps1|actions/image_to_pdf\.exe\.config|tools/pdf/.+)$' {
                $result.Pdf = $true
                break
            }
            '^actions/(.+)\.template\.ps1$' {
                if ($coveredScripts -contains $Matches[1]) {
                    [void]$result.Scripts.Add($Matches[1])
                }
                else {
                    $result.NotCovered.Add("$file (interactive action)")
                }
                break
            }
            '^actions/(media_info|change_audio_pitch_launcher)\.ps1$' {
                $result.NotCovered.Add("$file (interactive action)")
                break
            }
            '^dev/(context_menu\.psd1|context_menu_layout\.ps1|dev_menu\.ps1)$' {
                $result.Menu = $true
                break
            }
            '^(FFActions\.iss|dev/build_menu_iss\.ps1)$' {
                $result.NotCovered.Add("$file (installer compile)")
                break
            }
            '(\.md|^LICENSE|^\.gitignore|^\.gitattributes|^\.editorconfig|^\.github/.+)$' {
                break
            }
            default {
                $result.NotCovered.Add($file)
            }
        }
    }

    return $result
}

function Test-CaseSelected {
    param([string[]]$Scripts)

    if ($null -eq $selection -or $selection.All) {
        return $true
    }

    return @($Scripts | Where-Object { $selection.Scripts.Contains($_) }).Count -gt 0
}

function Test-GroupSelected {
    param([string]$Group)

    return ($null -eq $selection -or $selection.All -or $selection[$Group])
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

# Target: the script the picker starts, so a change in it also runs the chain.
$pickerCases = @(
    @{ Picker = 'extract_audio_picker'; Target = 'extract_audio'; Input = 'clip.mp4';  Button = 'WAV'; Output = '*.wav' }
    @{ Picker = 'convert_video_picker'; Target = 'convert_video'; Input = 'clip.mp4';  Button = 'MOV'; Output = '*.mov' }
    @{ Picker = 'convert_audio_picker'; Target = 'convert_audio'; Input = 'clip.wav';  Button = 'MP3'; Output = '*.mp3' }
    @{ Picker = 'convert_image_picker'; Target = 'convert_image'; Input = 'frame.png'; Button = 'BMP'; Output = '*.bmp' }
)

# Every character invalid in Windows file names, padded with spaces the output name trims.
$dialogPrefixInput = ' a<b>c:d"e/f\g|h*i?j '
$dialogPrefixField = ' a-b-c-d-e-f-g-h-i-j '
$dialogCases = @(
    @{ Script = 'cut_video'; Input = 'clip.mp4'; Button = 'OK';  Output = 'a-b-c-d-e-f-g-h-i-j - clip - CUT__00-00__00-03.mp4' }
    @{ Script = 'cut_audio'; Input = 'clip.wav'; Button = 'Cut'; Output = 'a-b-c-d-e-f-g-h-i-j - clip - CUT__00-00__00-03.wav' }
)

if ($Changed) {
    $selection = Get-ChangedSelection
    $selected = if ($selection.All) {
        'all checks'
    }
    else {
        @(
            if ($selection.Scripts.Count -gt 0) { 'actions: ' + (@($selection.Scripts | Sort-Object) -join ', ') }
            if ($selection.Pdf) { 'pdf runtime' }
            if ($selection.Menu) { 'dev menu' }
        ) -join '; '
    }

    Write-Host ('Changed since {0} ({1}): {2} file(s)' -f $Base, $selection.MergeBase.Substring(0, 7), $selection.Files.Count)
    Write-Host ('Selected: {0}' -f $(if ($selected) { $selected } else { 'nothing' }))
    if ($selection.NotCovered.Count -gt 0) {
        Write-Host ('Not covered: ' + ($selection.NotCovered -join ', ')) -ForegroundColor Yellow
    }

    Write-Host ''
    if (-not $selected) {
        exit 0
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

if ($null -eq $selection -or $selection.All -or $selection.Scripts.Count -gt 0) {
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
}

foreach ($runMode in $runModes) {
    foreach ($case in $actionCases) {
        if (Test-CaseSelected -Scripts @($case.Script)) {
            Test-ActionCase -Case $case -RunMode $runMode
        }
    }

    foreach ($case in $pickerCases) {
        if (-not (Test-CaseSelected -Scripts @($case.Picker, $case.Target))) {
            continue
        }

        if ($SkipPickers) {
            Add-Result "$($case.Picker) $($case.Button)" $runMode 'SKIP' '-SkipPickers'
        }
        else {
            Test-PickerCase -Case $case -RunMode $runMode
        }
    }

    foreach ($case in $dialogCases) {
        if (-not (Test-CaseSelected -Scripts @($case.Script))) {
            continue
        }

        if ($SkipDialogs) {
            Add-Result "$($case.Script) dialog" $runMode 'SKIP' '-SkipDialogs'
        }
        else {
            Test-DialogCase -Case $case -RunMode $runMode
        }
    }

    if (Test-GroupSelected -Group 'Pdf') {
        Test-PdfRuntime -RunMode $runMode
    }
}

if (Test-GroupSelected -Group 'Menu') {
    Test-DevMenu
}

$failed = @($results | Where-Object Status -eq 'FAIL').Count
$skipped = @($results | Where-Object Status -eq 'SKIP').Count
Write-Host ''
Write-Host ('{0} checks: {1} passed, {2} failed, {3} skipped. Work files: {4}' -f $results.Count, ($results.Count - $failed - $skipped), $failed, $skipped, $workRoot)
if ($selection -and $selection.NotCovered.Count -gt 0) {
    Write-Host ('Not covered: ' + ($selection.NotCovered -join ', ')) -ForegroundColor Yellow
}
exit $failed
