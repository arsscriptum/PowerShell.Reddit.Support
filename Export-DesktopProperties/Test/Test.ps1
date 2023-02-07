

<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

$PropsXml = "$PSScriptRoot\Props.xml"
$RootRel = "$PSScriptRoot\.."
$ScriptPath = Resolve-Path "$RootRel\Export-DesktopProperties.ps1"
. "$ScriptPath"

function Write-DesktopProperties{
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        [Parameter(Mandatory = $true, position = 0)]
        [WindowCoords]$TopLeft, 
        [Parameter(Mandatory = $true, position = 1)]
        [WindowCoords]$BottomRight,
        [Parameter(Mandatory = $true, position = 2)]
        [int]$Height,
        [Parameter(Mandatory = $true, position = 3)]
        [int]$Width,
        [Parameter(Mandatory = $true, position = 4)]
        [int]$Left,
        [Parameter(Mandatory = $true, position = 5)]
        [int]$Top,
        [Parameter(Mandatory = $true, position = 6)]
        [int]$Right,
        [Parameter(Mandatory = $true, position = 7)]
        [int]$Bottom,
        [Parameter(Mandatory = $false)]
        [string]$Name = ""
    )
    Write-Host "$Name" -f Yellow
    Write-Host "{`tTopLeft $($TopLeft.GetDumpStr())`n`tBottomRight $($BottomRight.GetDumpStr())`n`tHeight $Height`n`tWidth $Width`n`tLeft $Left`n`tTop $Top`n`tRight $Right`n`tBottom $Bottom`n}" -f DarkCyan
}



Write-Host "Export Windows Properties to $PropsXml" -f DarkCyan
Export-DesktopProperties -Path $PropsXml -Verbose


Write-Host "Nove the windows, they will be reset to the saved position after the countdown..."
5..0 | % {
    Start-Sleep 1
    Write-Host "$_ " -n  -f Yellow
}

Write-Host "Import Windows Properties from $PropsXml" -f DarkCyan
Import-DesktopProperties -Path $PropsXml -Verbose