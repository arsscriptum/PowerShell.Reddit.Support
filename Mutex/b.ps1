
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


Write-Host "Waiting for script A to terminate..."

$m=Wait-ForMutexInstance 
 
Write-Host "Script A terminated!" -f Green
DoWorkSon(10)

Unlock-MutexInstance