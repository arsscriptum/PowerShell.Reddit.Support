Write-Host "====================================================================" -f DarkYellow
Write-Host "                               Dark                                 " -f DarkRed
Write-Host "====================================================================" -f DarkYellow

$Blocking = $False
$datestr = (get-date).GetDateTimeFormats()[20]
Add-Content "$PSScriptRoot\Dark.txt" -Value "Dark $datestr"
if($Blocking){
    Start-Process -FilePath "$ENV:ComSpec" -ArgumentList "/K" -WindowStyle Normal -Wait    
}else{
    Start-Process -FilePath "$ENV:ComSpec" -ArgumentList "/C" -WindowStyle Normal -Wait
}
