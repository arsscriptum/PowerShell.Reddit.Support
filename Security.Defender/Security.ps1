<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜 
#̷𝓍   Security.ps1
#̷𝓍   
#̷𝓍   <guillaumeplante.qc@gmail.com>
#̷𝓍   https://arsscriptum.github.io/
#>



function SecUtilException{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]$Record,
        [Parameter(Mandatory=$false)]
        [switch]$ShowStack
    )       
    $formatstring = "{0}`n{1}"
    $fields = $Record.FullyQualifiedErrorId,$Record.Exception.ToString()
    $ExceptMsg=($formatstring -f $fields)
    $Stack=$Record.ScriptStackTrace
    Write-Host "[security util exception] -> " -NoNewLine -ForegroundColor Red; 
    Write-Host "$ExceptMsg" -ForegroundColor Yellow
    if($ShowStack){
        Write-Host "--stack begin--" -ForegroundColor Green
        Write-Host "$Stack" -ForegroundColor Gray  
        Write-Host "--stack end--`n" -ForegroundColor Green       
    }
}   



function Confirm-IsAdministrator  
{  
    $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    if((New-Object Security.Principal.WindowsPrincipal $user).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) ){
        return $true
    }
    return $false
}

function Set-ExclusionPaths  
{  
    $ExclusionPath = @()
    $ExclusionPath += 'c:\Scripts'
    $ExclusionPath += 'c:\Data'
    $ExclusionPath += 'c:\DOCUMENTS'
    ForEach($p in $ExclusionPath){
        Write-Host "Add path to excluded path list: $p" -f White
        Add-MpPreference -ExclusionPath $p
    }
}

function Disable-RealTimeProtection{

    [CmdletBinding(SupportsShouldProcess)]
    Param()   
    try{
        if(-not(Confirm-IsAdministrator)) { throw "Must be Administrator" ; return }

        <#̷#̷\
        #̷\   𝓡𝓣𝓟𝓻𝓸𝓽𝓮𝓬𝓽𝓲𝓸𝓷 𝓫𝓸𝓽𝓱𝓮𝓻𝓼 𝓶𝓮 𝔀𝓲𝓽𝓱 𝓪𝓵𝓵 𝓽𝓱𝓮 𝓹𝓸𝓹𝓾𝓹𝓼, 𝓹𝓵𝓾𝓼 𝓘 𝓱𝓪𝓿𝓮 𝓹𝓵𝓮𝓷𝓽𝔂 𝓸𝓯 𝓼𝓬𝓻𝓲𝓹𝓽𝓼 𝓽𝓸 𝓬𝓸𝓹𝔂
        #̷##>
        Write-Host "Disable-RealTimeProtection" -f White
        Write-Host " ==> LocalSettingOverrideDisableBehaviorMonitoring" -f DarkGray
        Write-Host " ==> LocalSettingOverrideDisableIntrusionPreventionSystem" -f DarkGray
        Write-Host " ==> LocalSettingOverrideDisableRealtimeMonitoring" -f DarkGray       
        Write-Host " ==> DisableAntiSpyware" -f Red       
        $null=New-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "LocalSettingOverrideDisableBehaviorMonitoring" 1 DWORD
        $null=New-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "LocalSettingOverrideDisableIntrusionPreventionSystem" 1 DWORD
        $null=New-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "LocalSettingOverrideDisableRealtimeMonitoring" 1 DWORD
        $null=New-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" "DisableAntiSpyware" 1 DWORD
    }catch{
        SecUtilException($_) -ShowStack
    }
}

function Disable-ExploitGuard{

    [CmdletBinding(SupportsShouldProcess)]
    Param()   
    try{
        if(-not(Confirm-IsAdministrator)) { throw "Must be Administrator" ; return }

        <#̷#̷\
        #̷\   𝓑𝓮𝓬𝓪𝓾𝓼𝓮 𝓘 𝓛𝓞𝓥𝓔 𝓔𝔁𝓹𝓵𝓸𝓲𝓽𝓼 :)
        #̷##>
        Write-Host "Disable-SmartScreen" -f White
        Write-Host " ==> EnableNetworkProtection" -f DarkGray
        Write-Host " ==> ExploitGuard_ASR_Rules" -f DarkGray
        Write-Host " ==> DisableIOAVProtection" -f DarkGray
        $null=New-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\Network Protection" "EnableNetworkProtection" 0 DWORD
        $null=New-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Windows Defender Exploit Guard\ASR" "ExploitGuard_ASR_Rules" 0 DWORD
        $null=New-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" "DisableIOAVProtection" 1 DWORD

    }catch{
        SecUtilException($_) -ShowStack
    }

}
function Disable-SmartScreen{
    # Define Parameters
    [CmdletBinding(SupportsShouldProcess)]
    Param()
    try{
        if(-not(Confirm-IsAdministrator)) { throw "Must be Administrator" ; return }

        Write-Host "Disable-SmartScreen" -f White
        Write-Host " ==> EnableSmartScreen" -f DarkGray
        Write-Host " ==> ShellSmartScreenLevel" -f DarkGray
        <#̷#̷\
        #̷\   𝓓𝓲𝓼𝓪𝓫𝓵𝓮 𝓼𝓶𝓪𝓻𝓽-𝓼𝓬𝓻𝓮𝓮𝓷 𝓭𝓮𝓽𝓮𝓬𝓽𝓲𝓸𝓷 𝓸𝓯 𝓶𝓪𝓵𝔀𝓪𝓻𝓮
        #̷##>
        $null=New-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableSmartScreen" 0 DWORD
        $null=New-RegistryValue "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "ShellSmartScreenLevel" "Warn" String

    }catch{
        SecUtilException($_) -ShowStack
    }
}

function Disable-SecurityFeatures{
    # Define Parameters
    [CmdletBinding(SupportsShouldProcess)]
    Param()  
    Disable-SmartScreen -Verbose:$Verbose -WhatIf:$WhatIf
    Disable-ExploitGuard -Verbose:$Verbose -WhatIf:$WhatIf
    Disable-RealTimeProtection -Verbose:$Verbose -WhatIf:$WhatIf
}