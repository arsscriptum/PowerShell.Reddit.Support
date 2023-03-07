Write-Host "====================================================================" -f DarkYellow
Write-Host "                               LIGHT                                " -f DarkRed
Write-Host "====================================================================" -f DarkYellow

$Blocking = $True
$datestr = (get-date).GetDateTimeFormats()[20]

Add-Content "$PSScriptRoot\Light.txt" -Value "LIGHT $datestr"
if($Blocking){
    Start-Process -FilePath "$ENV:ComSpec" -ArgumentList "/K" -WindowStyle Normal -Wait    
}else{
    Start-Process -FilePath "$ENV:ComSpec" -ArgumentList "/C" -WindowStyle Normal -Wait
}
