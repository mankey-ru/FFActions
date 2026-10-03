# Loader for dev\context_menu.psd1, dot-sourced by dev_menu.ps1 and build_menu_iss.ps1.
# Uses only language features and .NET, no module cmdlets: when ISCC is started
# from PowerShell 7, the Windows PowerShell it spawns inherits a PSModulePath
# that breaks cmdlet autoloading (Import-PowerShellDataFile, New-Object, ...).

$ContextMenuLayoutPath = [System.IO.Path]::Combine($PSScriptRoot, 'context_menu.psd1')

# CommandFlags ECF_SEPARATORBEFORE: Explorer draws a separator above a static submenu verb.
$ContextMenuSeparatorBefore = 0x20

function Read-ContextMenuLayout {
    # Same safety as Import-PowerShellDataFile: data-only restricted language.
    $layoutScript = [scriptblock]::Create([System.IO.File]::ReadAllText($ContextMenuLayoutPath))
    $layoutScript.CheckRestrictedLanguage([string[]]@(), [string[]]@(), $false)
    return $layoutScript.InvokeReturnAsIs()
}

# Flattens the layout into one entry per menu item. VerbName gets a numeric
# prefix because Explorer sorts static submenu verbs by registry key name.
# StartsGroup marks the first item after a '-'. Which item actually carries the
# separator is decided while writing, per extension (see New-ContextMenuSeparatorTracker),
# because an item can be skipped (component not installed) or cover fewer extensions.
function Get-ContextMenuEntries {
    $layout = Read-ContextMenuLayout
    $entries = [System.Collections.Generic.List[object]]::new()

    foreach ($family in $layout.Families) {
        $index = 0
        $startsGroup = $false

        foreach ($item in $family.Items) {
            if ($item -is [string]) {
                if ($item -ne '-') {
                    throw "Unknown entry '$item' in the $($family.Name) items of $ContextMenuLayoutPath."
                }

                $startsGroup = $true
                continue
            }

            foreach ($field in 'Label', 'Exe', 'Component') {
                if (-not $item[$field]) {
                    throw "A $($family.Name) item has no $field in $ContextMenuLayoutPath."
                }
            }

            $index++
            $extensions = $family.Extensions
            if ($item.Extensions) {
                $extensions = $item.Extensions
            }

            $entries.Add([PSCustomObject]@{
                Family       = $family.Name
                StartsGroup  = $startsGroup
                Extensions   = [string[]]$extensions
                VerbName     = ('{0:D2}_{1}' -f $index, [System.IO.Path]::GetFileNameWithoutExtension($item.Exe))
                Label        = $item.Label
                Exe          = $item.Exe
                Icon         = [string]$item.Icon
                Component    = $item.Component
                AllUsers     = [bool]$item.AllUsers
            })
            $startsGroup = $false
        }
    }

    return ,$entries.ToArray()
}

# Per-extension separator state for one pass over the entries, mirrored by the
# installer's [Code] (StartContextMenuGroup / ApplyActionMenuList): a group start
# makes a separator pending for every extension that already has an item in the
# family, and the next item written for that extension takes it. No leading,
# trailing or doubled separators, whatever subset of items gets written.
function New-ContextMenuSeparatorTracker {
    return @{
        Family  = $null
        Written = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
        Pending = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    }
}

# Call once per entry, before writing it.
function Enter-ContextMenuEntry {
    param($Tracker, $Entry)

    if ($Entry.Family -ne $Tracker.Family) {
        $Tracker.Family = $Entry.Family
        $Tracker.Written.Clear()
        $Tracker.Pending.Clear()
    }

    if ($Entry.StartsGroup) {
        $Tracker.Pending.UnionWith($Tracker.Written)
    }
}

# Call for each extension the entry is written to; returns its CommandFlags.
function Get-ContextMenuItemFlags {
    param($Tracker, [string]$Extension)

    [void]$Tracker.Written.Add($Extension)
    if ($Tracker.Pending.Remove($Extension)) {
        return $ContextMenuSeparatorBefore
    }

    return 0
}
