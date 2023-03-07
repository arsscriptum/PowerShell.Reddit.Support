
[CmdletBinding(SupportsShouldProcess)]
param()


$CopyScript = "$PSScriptRoot\Copy-CustomLocation.ps1"
. "$CopyScript"


#$filelist = Get-ChildItem -Path "F:\Temp\COPY_SOURCE" -File -Filter "*.ps1" -Recurse | Select -First 5 | Select -ExpandProperty FullName
$filelist = Get-Content -Path "F:\Temp\COPY_SOURCE_LIST.txt"
Copy-CustomLocation -Path $filelist -Destination "F:\Temp\COPY_DEST"