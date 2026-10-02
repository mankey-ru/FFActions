param(
    [switch]$Uninstall
)

# Registers an "FFActionsDev" Explorer context menu (current user only, no admin)
# that runs the executables built in this repo's actions\ folder.
# The layout comes from context_menu.psd1 (shared with the installer); re-run
# this script after editing it. -Uninstall removes the menu.

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'context_menu_layout.ps1')

$menuName = 'FFActionsDev'
$repoRoot = Split-Path -Parent $PSScriptRoot
$actionsDir = Join-Path $repoRoot 'actions'
$menuIconsDir = Join-Path $repoRoot 'tools\icons\icones menus'
$rootIconPath = Join-Path $repoRoot 'tools\icons\ffactions.ico'
$associationsPath = 'Software\Classes\SystemFileAssociations'
$hive = [Microsoft.Win32.Registry]::CurrentUser

function Set-RegistryValue {
    param(
        [Parameter(Mandatory = $true)][string]$KeyPath,
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)][string]$Name,
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)]$Value,
        [Microsoft.Win32.RegistryValueKind]$Kind = [Microsoft.Win32.RegistryValueKind]::String
    )

    $key = $hive.CreateSubKey($KeyPath)
    try {
        $key.SetValue($Name, $Value, $Kind)
    }
    finally {
        $key.Dispose()
    }
}

# Removes the menu from every extension, including ones no longer in the layout.
function Remove-DevMenu {
    $associations = $hive.OpenSubKey($associationsPath)
    if ($null -eq $associations) {
        return 0
    }

    try {
        $extensions = $associations.GetSubKeyNames()
    }
    finally {
        $associations.Dispose()
    }

    $removed = 0
    foreach ($extension in $extensions) {
        $menuPath = "$associationsPath\$extension\shell\$menuName"
        $menuKey = $hive.OpenSubKey($menuPath)
        if ($null -eq $menuKey) {
            continue
        }

        $menuKey.Dispose()
        $hive.DeleteSubKeyTree($menuPath)
        $removed++
    }

    return $removed
}

function Update-ShellAssociations {
    if (-not ('FFActionsDev.Shell32' -as [type])) {
        Add-Type -Namespace 'FFActionsDev' -Name 'Shell32' -MemberDefinition @'
[DllImport("shell32.dll")]
public static extern void SHChangeNotify(int eventId, uint flags, IntPtr item1, IntPtr item2);
'@
    }

    # SHCNE_ASSOCCHANGED, SHCNF_IDLIST
    [FFActionsDev.Shell32]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
}

$removedCount = Remove-DevMenu

if ($Uninstall) {
    Update-ShellAssociations
    Write-Host "$menuName menu removed from $removedCount extension(s)."
    return
}

$missingFiles = New-Object System.Collections.Generic.List[string]
$menuExtensions = @{}

foreach ($entry in (Get-ContextMenuEntries)) {
    $exePath = Join-Path $actionsDir $entry.Exe
    if (-not (Test-Path -LiteralPath $exePath)) {
        $missingFiles.Add($exePath)
    }

    $iconPath = ''
    if ($entry.Icon) {
        $iconPath = Join-Path $menuIconsDir $entry.Icon
        if (-not (Test-Path -LiteralPath $iconPath)) {
            $missingFiles.Add($iconPath)
            $iconPath = ''
        }
    }

    $command = '"{0}" "%1"' -f $exePath

    foreach ($extension in $entry.Extensions) {
        $menuPath = "$associationsPath\$extension\shell\$menuName"
        if (-not $menuExtensions.ContainsKey($extension)) {
            Set-RegistryValue -KeyPath $menuPath -Name 'MUIVerb' -Value $menuName
            Set-RegistryValue -KeyPath $menuPath -Name 'SubCommands' -Value ''
            Set-RegistryValue -KeyPath $menuPath -Name 'Icon' -Value $rootIconPath
            $menuExtensions[$extension] = $true
        }

        $verbPath = "$menuPath\shell\$($entry.VerbName)"
        Set-RegistryValue -KeyPath $verbPath -Name 'MUIVerb' -Value $entry.Label
        if ($iconPath) {
            Set-RegistryValue -KeyPath $verbPath -Name 'Icon' -Value $iconPath
        }
        if ($entry.CommandFlags) {
            Set-RegistryValue -KeyPath $verbPath -Name 'CommandFlags' -Value $entry.CommandFlags -Kind DWord
        }
        Set-RegistryValue -KeyPath "$verbPath\command" -Name '' -Value $command
    }
}

Update-ShellAssociations

Write-Host "$menuName menu registered for $($menuExtensions.Count) extension(s) -> $actionsDir"
foreach ($file in ($missingFiles | Sort-Object -Unique)) {
    Write-Warning "Missing: $file"
}
