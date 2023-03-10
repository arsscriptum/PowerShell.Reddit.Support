
<#
#ฬท๐   ๐๐ก๐ข ๐ข๐๐ก๐๐๐ฃ๐ค๐
#ฬท๐   ๐ตโโโโโ๐ดโโโโโ๐ผโโโโโ๐ชโโโโโ๐ทโโโโโ๐ธโโโโโ๐ญโโโโโ๐ชโโโโโ๐ฑโโโโโ๐ฑโโโโโ ๐ธโโโโโ๐จโโโโโ๐ทโโโโโ๐ฎโโโโโ๐ตโโโโโ๐นโโโโโ ๐งโโโโโ๐พโโโโโ ๐ฌโโโโโ๐บโโโโโ๐ฎโโโโโ๐ฑโโโโโ๐ฑโโโโโ๐ฆโโโโโ๐บโโโโโ๐ฒโโโโโ๐ชโโโโโ๐ตโโโโโ๐ฑโโโโโ๐ฆโโโโโ๐ณโโโโโ๐นโโโโโ๐ชโโโโโ.๐ถโโโโโ๐จโโโโโ@๐ฌโโโโโ๐ฒโโโโโ๐ฆโโโโโ๐ฎโโโโโ๐ฑโโโโโ.๐จโโโโโ๐ดโโโโโ๐ฒโโโโโ
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
