
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


[CmdletBinding(SupportsShouldProcess)] 
param()

. "$PSScriptRoot\Mutex.ps1"

Function DoWorkSon([int]$WaitFor){
    Write-Host "`n[Starting Work] " -f DarkCyan -n 
    For($i = $WaitFor ; $i -gt 0 ; $i-- ){
        Start-Sleep 1
        Write-Host "." -n
    }
    Write-Host "`n[Stopped]" -f DarkCyan
}


$ok = Lock-MutexInstance
if($ok){
    Write-Host "Mutex Created"
    DoWorkSon(20)

    Exit-Mutex
    Write-Host "Mutex Disposed"
}else{
    Write-Host "Cannot Lock Mutex"
    return
}


Start-Sleep 1
Write-Host "Lets wait for the other script to terminate..."
$m=Wait-ForMutexInstance 
Write-Host "Ok, OUR TURN!"
Unlock-MutexInstance
Write-Host "Mutex Disposed"