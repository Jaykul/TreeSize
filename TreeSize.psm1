# PowerShell 5 feature (oops, has to be the "first thing" in a script)
# In PowerShell 4 we have to use Import-Namespace from the reflection module
using namespace System.IO

## This is not working ... I guess we need a format file to show it right
## The objects appear to be typed correctly ( Get-Member shows them as "System.IO.TreeView" )
# Update-TypeData -TypeName "System.IO.TreeView" -DefaultDisplayProperty TreeName -DefaultDisplayPropertySet TreeName, Length -Force

function Get-TreeSize {
    #.Synopsis
    #   Recursively lists provider items and sums their lengths
    #.Description
    #   The actual objects are the same file system objects you'd get from Get-ChildItem -Recurse
    #   But with properties added to them like Depth and with Length calculated for the folders
    #   Then a custom formmatter makes them come out like this:
    #
    #   PS> Get-TreeSize
    #
    #   Localization\ 12021
    #   ├─ En\        1339
    #   ├─ En-US\     2025
    #
    #  Or like this:
    #
    #   PS> Get-TreeSize -ShowFiles
    #
    #   Localization\           12021
    #   ├─ En\                  1339
    #      ├─ numbers.psd1      86
    #      ├─ UserSettings.psd1 1253
    #   ├─ En-US\               2025
    #      ├─ Localization.psd1 958
    #      ├─ numbers.psd1      67
    #      ├─ UserSettings.psd1 1000
    #   ├─ Localization.psd1    6698
    #   ├─ UserSettings.psd1    1959
    #
    #  Or like this:
    #
    #   PS> Get-TreeSize | Format-Custom
    #
    #   Localization\ (11.74 KB)
    #   ├─ En\ (1.31 KB)
    #   ├─ En-US\ (1.98 KB)    

	[CmdletBinding()]
    param(
        # The root of the tree view
        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias("PSPath")]
        $Path = $pwd,

        # Whether to show files or just folder in the resulting tree
        [Parameter()]
        [Switch]$ShowFiles,

        # How deep to start the indent (hypothetically for splitting up the work)
        # Defaults to the number of elements in $Path.Split("\")
        [int]$Depth = $((Convert-Path $Path).Split([Path]::DirectorySeparatorChar).Length)
    )
    process {
        # I'm going to choose to show FileSystem paths here
        # Which means any PowerShell "PSDrive" will be lost
        # We could change that later ...
        $Local:Path = Convert-Path $Path
        $Local:Length = 0

        # Cache the recursive output so it comes out in the right order
        $Children = @(
            switch(Get-ChildItem -Path $Local:Path -Force) {
                {$_ -is [DirectoryInfo]} {
                    # Recurse! And don't forget to pass all the parameters down ...
                    $Info = Get-TreeSize -Path $_.FullName -ShowFiles:$ShowFiles -Depth ($Depth + 1)
                    # Running total ...
                    # ROFL: this is the length of the array. stupid thing.
                    $Local:Length += $Info[0].Length
                    $Info
                }
                {$_ -is [FileInfo]} {
                    # Running total ...
                    $Local:Length += $_.Length
                    if($ShowFiles) { $_ }
                }
            }
        )
        @(
            # After we recurse, we know the size of this object, and can output.
            Get-Item -Path $Local:Path | Add-Member NoteProperty Length $Local:Length -Force -Passthru
            # Now output the child items ... 
            $Children
        ) |

            ForEach-Object { $_.PSTypeNames.Insert(0, "System.IO.TreeView"); $_ } |
            Add-Member ScriptProperty Depth { $this.FullName.Split([Path]::DirectorySeparatorChar).Length } -Passthru -Force |
            # NOTE: Even though this is a ScriptProperty
            # We have to add it here, dynamically, instead of in a types file because we use $Depth
            Add-Member ScriptProperty "TreeName" { ("   " * [Math]::Max(($this.Depth - $Depth -1), 0)) + $(if($this.Depth -ne $Depth){"├─ "}) + $this.Name + $(if($this.PSIsContainer){"\"})} -Passthru -Force

    }
}

Set-Alias TreeSize Get-TreeSize
