
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>



function Get-NotebookFanControlPath{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $expectedLocations=@("${ENV:ProgramFiles(x86)}\NoteBook FanControl", "$ENV:ProgramFiles\NoteBook FanControl")
    $ffFiles=$expectedLocations|%{Join-Path $_ 'nbfc.exe'}
    [String[]]$vPath=@($expectedLocations|?{test-path $_})
    $vPathCount = $vPath.Count
    if($vPathCount){
        return $vPath[0]
    }
    else{
        return $Null
    }
}

function Get-NotebookFanControlExe{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $expectedLocations=@("${ENV:ProgramFiles(x86)}\NoteBook FanControl", "$ENV:ProgramFiles\NoteBook FanControl")
    $ffFiles=$expectedLocations|%{Join-Path $_ 'nbfc.exe'}
    [String[]]$validFiles=@($ffFiles|?{test-path $_})
    $validFilesCount = $validFiles.Count
    if($validFilesCount){
        return $validFiles[0]
    }
    else{
        return $Null
    }
}

function Push-NotebookFanControlPath{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="exp")]
        [Alias("e")]
        [switch]$Explorer
    )
    $p = Get-NotebookFanControlPath
    pushd $p

    if($Explorer){
        $e = (Get-Command 'explorer.exe').Source
        &"$e" "$p"   
    }
}


function Get-FcStatus{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $NotebookFanControlExe=Get-NotebookFanControlExe
   

    $fs = (InvokeRunNbfc -c "status" -a "-a").Output

    [hashtable]$CurrentStatus = [ordered]@{}
    ForEach($l in $fs){
        $values = $l.split(':')
        if(($values -ne $Null) -And ($values.Count -eq 2)){
            $cfgname = $values[0].Trim()
            $cfgvalue = $values[1].Trim()
            if($CurrentStatus[$cfgname] -ne $Null){
                $cfgname += ' #2'
            }

            $Null = $CurrentStatus.Add($cfgname,$cfgvalue)
        }
    }

    return $CurrentStatus
}
function Get-FcTemperature{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $s = Get-FcStatus

    return $s.'Temperature'
}

function Get-FcServiceStatus{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $s = Get-FcStatus

    return ($s.'Service enabled' -eq 'True')
}

function Stop-FcService{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $NotebookFanControlExe=Get-NotebookFanControlExe
   
    Write-Host "Start-FanControlService, please wait..."
    & "$NotebookFanControlExe" stop
    Start-Sleep 3
    $s = Get-FcStatus

    $srv = $s.'Service enabled'
    Write-Host "Service enabled: $srv"
}


function Start-FcService{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $NotebookFanControlExe=Get-NotebookFanControlExe
   
    Write-Host "Start-FanControlService, please wait..."
    & "$NotebookFanControlExe" start
    Start-Sleep 3
    $s = Get-FcStatus

    $srv = $s.'Service enabled'
    Write-Host "Service Started: $srv"
}


function Set-FanSpeed{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="speed")]
        [Alias("s")]
        [int]$Speed,
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="speed")]
        [Alias("i")]
        [ValidateSet(-1,0,1)]
        [int]$Index=-1
    )

    $NotebookFanControlExe=Get-NotebookFanControlExe
   
    if($Index -eq -1){
        Write-Host "Set Fan Speed to $Speed for fan no $Index"
        & "$NotebookFanControlExe" set -f 0 -s $Speed
        & "$NotebookFanControlExe" set -f 1 -s $Speed
        Write-Host "Fan #0: Set Speed to $Speed`nFan #1: Set Speed to $Speed"
    }else {
        Write-Host "Fan #$Index`: Set Speed to $Speed"
        & "$NotebookFanControlExe" set -f $Index -s $Speed
    }
    
}


function Test-Fconfig{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, HelpMessage="speed")]
        [Alias("c")]
        [string]$Config
    )

    $NotebookFanControlExe=Get-NotebookFanControlExe
   
    $AllCfgs = & "$NotebookFanControlExe" config -l
    ForEach($cfg in $AllCfgs){
        if($cfg -eq $Config){
            return $true
        }
    }
    return $false
}


function Set-FcConfig{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ValueFromPipeline=$true, HelpMessage="speed")]
        [Alias("c")]
        [string]$Config,
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="exp")]
        [Alias("l")]
        [switch]$List
    )

    if($List){
        $NotebookFanControlExe=Get-NotebookFanControlExe
   
        Write-Host "LISTING ALL POSSIBLE CONFIGURATIONS" -f DarkGreen
        & "$NotebookFanControlExe" config -l
        return
    }
    $Valid = Test-FanControlConfig -Config $Config
    if($Valid -eq $False){
        Write-Host "Invalid Config `"$Config`" . Use -l argument for listing"
        return
    }
    $NotebookFanControlExe=Get-NotebookFanControlExe
   
    Write-Host "Set Fan Config to $Config"
    & "$NotebookFanControlExe" config -s "$Config"
}



function Set-FcAutoConfig{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    Set-FcConfig -Config "my_simple_zbook_config"
    Start-FcService

}
