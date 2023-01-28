
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>



function Get-MutexInstance{
    [CmdletBinding()]
    param()

    $m = Get-Variable -Name "CoreMutex" -ValueOnly -Scope Global -ErrorAction Ignore
    $m
}


function Lock-MutexInstance {
<#
    .SYNOPSIS
        Create and Lock a new mutex instance.
    .DESCRIPTION
        Create and Lock a new mutex, on failure, returns null
#>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    $wasCreated = $false
    [System.Threading.Mutex]$CoreMutex = New-Object System.Threading.Mutex( $false, "CoreMutex", [ref]$wasCreated)

    if($wasCreated){
        Write-Verbose "[New-MutexInstance] : Mutex Created."
        Set-Variable -Name "CoreMutex" -Value $CoreMutex -Scope Global -Option AllScope -Visibility Public -Force -ErrorAction Ignore
        Write-Verbose "[New-MutexInstance] : Mutex WaitOne()"
        $CoreMutex.WaitOne()
        $CoreMutex
    }else{
        Write-Verbose "[New-MutexInstance] : Mutex Creation failed"
    }
    $null
}


function Wait-ForMutexInstance 
{
<#
    .SYNOPSIS
        Wait for the Core mutex instance and lock it before returning
    .DESCRIPTION
        Wait for the Core mutex instance and lock it before returning once you get this function
        result, you are the mutex owner
#>  
    [CmdletBinding(SupportsShouldProcess)] 
    param()

    Write-Verbose "[Wait-OnMutexInstance] start waiting for `"CoreMutex`""
    try
    {
        $MutexInstance = [System.Threading.Mutex]::new($true, "CoreMutex")
        if($MutexInstance -eq $null){ throw "Invalid Mutex Instance (was it created with New-MutexInstance?)" }

        while (-not $MutexInstance.WaitOne(500))
        {
            Start-Sleep -m 500;
        }
        Write-Verbose "[Wait-OnMutexInstance] stop waiting for `"CoreMutex`""
        Set-Variable -Name "CoreMutex" -Value $MutexInstance -Scope Global -Option AllScope -Visibility Public -Force -ErrorAction Ignore
        return $MutexInstance
    } 
    catch [System.Threading.AbandonedMutexException] 
    {
        $MutexInstance = [System.Threading.Mutex]::new($False, "CoreMutex")
        return Wait-OnMutexInstance
    }
}


function Unlock-MutexInstance   {
    [CmdletBinding()]
    param()
    $MutexInstance = Get-MutexInstance
    if($MutexInstance -eq $null){ throw "Invalid Mutex Instance (was it created with New-MutexInstance?)" }

    $MutexInstance.ReleaseMutex()
    Write-Verbose "[Exit-Mutex] Mutex Released"
    $MutexInstance.Dispose()
    Set-Variable -Name "CoreMutex" -Value $null -Scope Global -Option AllScope -Visibility Public -Force -ErrorAction Ignore
}
