param(
    [switch]$Uninstall
)

# Registers an "FFActionsDev" Explorer context menu (current user only, no admin)
# that runs the executables built in this repo's actions\ folder.
# The layout lives in dev_menu.psd1; re-run this script after editing it or
# after rebuilding. -Uninstall removes the menu.

$ErrorActionPreference = 'Stop'

$menuName = 'FFActionsDev'
$repoRoot = Split-Path -Parent $PSScriptRoot
$actionsDir = Join-Path $repoRoot 'actions'
$menuIconsDir = Join-Path $repoRoot 'tools\icons\icones menus'
$rootIconPath = Join-Path $repoRoot 'tools\icons\ffactions.ico'
$associationsPath = 'Software\Classes\SystemFileAssociations'
$hive = [Microsoft.Win32.Registry]::CurrentUser

function Set-RegistryString {
    param(
        [Parameter(Mandatory = $true)][string]$KeyPath,
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)][string]$Name,
        [AllowEmptyString()]
        [Parameter(Mandatory = $true)][string]$Value
    )

    $key = $hive.CreateSubKey($KeyPath)
    try {
        $key.SetValue($Name, $Value, [Microsoft.Win32.RegistryValueKind]::String)
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

$layout = Import-PowerShellDataFile -LiteralPath (Join-Path $PSScriptRoot 'dev_menu.psd1')
$missingFiles = New-Object System.Collections.Generic.List[string]
$menuExtensions = @{}

foreach ($family in $layout.Families) {
    $index = 0
    foreach ($item in $family.Items) {
        $index++
        $exePath = Join-Path $actionsDir $item.Exe
        if (-not (Test-Path -LiteralPath $exePath)) {
            $missingFiles.Add($exePath)
        }

        $iconPath = ''
        if ($item.Icon) {
            $iconPath = Join-Path $menuIconsDir $item.Icon
            if (-not (Test-Path -LiteralPath $iconPath)) {
                $missingFiles.Add($iconPath)
                $iconPath = ''
            }
        }

        $extensions = $family.Extensions
        if ($item.Extensions) {
            $extensions = $item.Extensions
        }

        # Explorer sorts static submenu verbs by key name, so the numeric prefix sets the order.
        $verbName = '{0:D2}_{1}' -f $index, [System.IO.Path]::GetFileNameWithoutExtension($item.Exe)
        $command = '"{0}" "%1"' -f $exePath

        foreach ($extension in $extensions) {
            $menuPath = "$associationsPath\$extension\shell\$menuName"
            if (-not $menuExtensions.ContainsKey($extension)) {
                Set-RegistryString -KeyPath $menuPath -Name 'MUIVerb' -Value $menuName
                Set-RegistryString -KeyPath $menuPath -Name 'SubCommands' -Value ''
                Set-RegistryString -KeyPath $menuPath -Name 'Icon' -Value $rootIconPath
                $menuExtensions[$extension] = $true
            }

            $verbPath = "$menuPath\shell\$verbName"
            Set-RegistryString -KeyPath $verbPath -Name 'MUIVerb' -Value $item.Label
            if ($iconPath) {
                Set-RegistryString -KeyPath $verbPath -Name 'Icon' -Value $iconPath
            }
            Set-RegistryString -KeyPath "$verbPath\command" -Name '' -Value $command
        }
    }
}

Update-ShellAssociations

Write-Host "$menuName menu registered for $($menuExtensions.Count) extension(s) -> $actionsDir"
foreach ($file in ($missingFiles | Sort-Object -Unique)) {
    Write-Warning "Missing: $file"
}
