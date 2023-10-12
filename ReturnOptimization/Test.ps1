
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>



function Convert-BytesToHumanReadable{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [uint64]$Bytes
    )   

    [string]$res_str = ""
    if($Bytes -gt 1TB){ 
        $res_str =  "{0:n2} TB" -f ($Bytes / 1TB) 
    }elseif($Bytes -gt 1GB){ 
        $res_str =  "{0:n2} GB" -f ($Bytes / 1GB) 
    }elseif($Bytes -gt 1MB){ 
        $res_str =  "{0:n2} MB" -f ($Bytes / 1MB) 
    }elseif($Bytes -gt 1KB){
        $res_str =  "{0:n2} KB" -f ($Bytes / 1KB) 
    }else{
        $res_str =  "{0:n2} Bytes" -f $Bytes      
    }
    
    return $res_str
}


    <#
     Read a Byte Array, return the data with Write-Output -NoEnumerate (not unrolling)
    #>
    function Read-ByteArray_NoEnum([string]$Path) {
      $fs = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
      [byte[]]$file_bytes = [byte[]]::new($fs.Length)
      $Null = $fs.Read($file_bytes, 0, $fs.Length) 
      $fs.Close()
      $fs.Dispose()

      # Using Write-Output
      Write-Output $file_bytes -NoEnumerate
    }  
    
    <#
      Read a Byte Array, return the data in another object using the unary comma
    #>
    function Read-ByteArray_Unary([string]$Path) {
      $fs = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
      [byte[]]$file_bytes = [byte[]]::new($fs.Length)
      $Null = $fs.Read($file_bytes, 0, $fs.Length) 
      $fs.Close()
      $fs.Dispose()
      
      # return using unary comma
      ,$file_bytes
    } 

    <#
     Read a Byte Array, return the data normally (powershell will unroll the object)
    #>
    function Read-ByteArray_Ret([string]$Path) {
      $fs = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
      [byte[]]$file_bytes = [byte[]]::new($fs.Length)
      $Null = $fs.Read($file_bytes, 0, $fs.Length) 
      $fs.Close()
      $fs.Dispose()
      
      # simple return
      $file_bytes
    }  



  function Test-ReadByteArrays{
      [CmdletBinding(SupportsShouldProcess)]
      param()

      $f = "$PSScriptRoot\data.gif"
      if(-not(Test-Path -Path "$f" -PathType Leaf)){
          Write-Host "Getting Test File (tmp)..." -f DarkCyan
          $u = "https://arsscriptum.github.io/files/ufo.gif"
          $pp = $ProgressPreference
          $ProgressPreference = 'SilentlyContinue'  
          $req = Invoke-WebRequest -Uri $u -OutFile "$f" -PAssThru
          $ProgressPreference = $pp
          if($req.StatusCode -ne 200){throw "error"}
      }

      $file_length = (Get-Item $f).Length
      $size_str = Convert-BytesToHumanReadable $file_length


      $title =  "`nStarting Test. Using file length {0} ({1} bytes)" -f $size_str, $file_length
      Write-Host "$title`n" -f Red
      Write-Host "  EXEC TIME `t        FUNCTION      `t METHOD USED" -f Cyan
      Write-Host "------------`t----------------------`t------------------------------`n" -f DarkGray

      $time_spent = Measure-Command { $b = [System.IO.File]::ReadAllBytes("$f")} 
      $log_results =  "{0:N2} seconds`tReadAllBytes         `tUsing Native ReadAllBytes" -f $time_spent.TotalSeconds
      Write-Host "$log_results" -f DarkYellow

      $time_spent = Measure-Command { $b = Read-ByteArray_NoEnum("$f") } 
      $log_results =  "{0:N2} seconds`tRead-ByteArray_NoEnum`tUsing Write-Output -NoEnumerate" -f $time_spent.TotalSeconds
      Write-Host "$log_results" -f White

      $time_spent = Measure-Command { $b = Read-ByteArray_Unary("$f") } 
      $log_results =  "{0:N2} seconds`tRead-ByteArray_Unary `tReturn using unary comma" -f $time_spent.TotalSeconds
      Write-Host "$log_results" -f DarkCyan
     
      $time_spent = Measure-Command { $b = Read-ByteArray_Ret("$f") } 
      $log_results =  "{0:N2} seconds`tRead-ByteArray_Ret   `tSimple Return" -f $time_spent.TotalSeconds
      Write-Host "$log_results" -f DarkRed

  }

  Test-ReadByteArrays