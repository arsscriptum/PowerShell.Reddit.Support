
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>



function Get-DisplaySwitchPath {
    [CmdletBinding(SupportsShouldProcess)]
    param()
    try{
        $path = ''
        $DisplaySwitchCmd = Get-Command 'DisplaySwitch.exe' -ErrorAction Ignore
        if ($DisplaySwitchCmd) {
            $path = $DisplaySwitchCmd.Source
        }elseif(Test-Path "$ENV:SystemRoot\System32\DisplaySwitch.exe"){
            $path = "$ENV:SystemRoot\System32\DisplaySwitch.exe"
        }else{
          throw "cannot find DisplaySwitch"
        }
        return $path
    }catch{
        Write-Error $_
    }
}  

 
<#
    .SYNOPSIS
        Specify which display to use and how to use it.

    .DESCRIPTION
        Use DisplaySwitch.exe to Specify which display to use and how to use it.

    .NOTES

       /internal    Switch to use the primary display only.
       1            All other connected displays will be disabled. 

       /clone       The primary display will be mirrored on a second screen.
       2        

       /extend      Expand the Desktop to a secondary display.
       3            This allows one desktop to span multiple displays. (Default).

       /external    Switch to the external display only (second screen).
       4            The current main display will be disabled.
#>
function Set-DisplayMode{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True, Position = 0)]
        [ValidateSet('internal', 'clone', 'extend', 'external')]
        [Alias("m")]
        [string]$Mode
    )


    $DisplaySwitchPath = Get-DisplaySwitchPath
    $Argument = "/{0}" -f $Mode
    Write-Host "SETTING DISPLAY MODE TO `"$Mode`"" -f DarkYellow
    & "$DisplaySwitchPath" "$Argument"

}
