<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

Write-Host "Creating 100 base dirs...." -f Red
0..100 | % { $n = $_
    $dir = "{0}\{1:d4}" -f "$PSScriptRoot",$n
    New-Item -Path "$dir" -ItemType Directory -Force -ErrorAction Ignore | Out-Null
}


$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$AccessRule = [System.Security.AccessControl.FileSystemAccessRule]::new("$CurrentUser",'Read','none', 'NoPropagateInherit', "Allow")
$MyStrictAcl=[System.Security.AccessControl.DirectorySecurity]::new()
$MyStrictAcl.SetAccessRule($AccessRule)
$MyStrictAcl.SetAccessRuleProtection($True, $False)

$set_acl = $false
$normals = 0
$specials = 0
Write-Host "Creating 100 base dirs...." -f Red
0..100 | % { $n = $_
    $dir = "{0}\{1:d4}" -f "$PSScriptRoot",$n
    $a = @('microsoft.com','google.com','videotron.com','bell.ca','military.com','panasonic.com')
    $anum = $a.Count - 1
    $var = Get-Random -Minimum 0 -Maximum $anum
    $lottery = Get-Random -Minimum 0 -Maximum 100
    $dirname = "{0:d6}-{1}" -f ($n*(Get-Random -Minimum 0 -Maximum 4)),([string]::new("a",$n) -as [string])
    if($lottery -lt 15){ 
        $specials++
        $dirname = $a[$var] 
        $set_acl = $true
    }else{
        $set_acl = $false
        $normals++
    }
    $newdir = Join-Path $dir $dirname
    New-Item -Path "$newdir" -ItemType Directory -Force -ErrorAction Ignore | Out-Null
    if($set_acl) { $MyStrictAcl | Set-Acl "$newdir" }
}

$totals = $normals + $specials

Write-Host "Created $totals directories, $specials specials and $normals normals"