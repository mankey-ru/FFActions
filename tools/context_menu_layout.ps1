# Loader for tools\context_menu.psd1, dot-sourced by dev_menu.ps1 and build_menu_iss.ps1.
# Uses only language features and .NET, no module cmdlets: when ISCC is started
# from PowerShell 7, the Windows PowerShell it spawns inherits a PSModulePath
# that breaks cmdlet autoloading (Import-PowerShellDataFile, New-Object, ...).

$ContextMenuLayoutPath = [System.IO.Path]::Combine($PSScriptRoot, 'context_menu.psd1')

# ECF_SEPARATORBEFORE: Explorer draws a separator above a static submenu verb.
$ContextMenuSeparatorBefore = 0x20

function Read-ContextMenuLayout {
    # Same safety as Import-PowerShellDataFile: data-only restricted language.
    $layoutScript = [scriptblock]::Create([System.IO.File]::ReadAllText($ContextMenuLayoutPath))
    $layoutScript.CheckRestrictedLanguage([string[]]@(), [string[]]@(), $false)
    return $layoutScript.InvokeReturnAsIs()
}

# Flattens the layout into one entry per menu item. VerbName gets a numeric
# prefix because Explorer sorts static submenu verbs by registry key name.
function Get-ContextMenuEntries {
    $layout = Read-ContextMenuLayout
    $entries = [System.Collections.Generic.List[object]]::new()

    foreach ($family in $layout.Families) {
        $index = 0
        $separatorPending = $false

        foreach ($item in $family.Items) {
            if ($item -is [string]) {
                if ($item -ne '-') {
                    throw "Unknown entry '$item' in the $($family.Name) items of $ContextMenuLayoutPath."
                }

                $separatorPending = $true
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

            $commandFlags = 0
            if ($separatorPending) {
                $commandFlags = $ContextMenuSeparatorBefore
                $separatorPending = $false
            }

            $entries.Add([PSCustomObject]@{
                Extensions   = [string[]]$extensions
                VerbName     = ('{0:D2}_{1}' -f $index, [System.IO.Path]::GetFileNameWithoutExtension($item.Exe))
                Label        = $item.Label
                Exe          = $item.Exe
                Icon         = [string]$item.Icon
                Component    = $item.Component
                AllUsers     = [bool]$item.AllUsers
                CommandFlags = $commandFlags
            })
        }
    }

    return ,$entries.ToArray()
}
