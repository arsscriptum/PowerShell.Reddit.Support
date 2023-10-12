
## PowerShell Best Practice : Return Optimization

[Blog Post : PowerShell Best Practice: Returning BIG Objects from Functions](https://arsscriptum.github.io/blog/returnobj-optimization/)



Let's make a function that will return an array of bytes:

```powershell
  function Read-ByteArray([string]$Path) {
    $fs = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    [byte[]]$file_bytes = [byte[]]::new($fs.Length)
    $Null = $fs.Read($file_bytes, 0, $fs.Length) 
    $fs.Close()
    $fs.Dispose()
    $file_bytes
  }  
```

*Forget that there is a native .NET function to read bytes and follow me a bit...*

When you use that function to read a big file, like something in the order of hundreds of Megabytes, you will notice that the function takes a long time to execute. It should be right? I mean it's just reading bytes, not processing them...

## Returning BIG objects in PowerShell

When returning big arrays from function in PowerShell, ***you need to take into account that PowerShell unrolls your objects when you return them.***

The reason for the performance hang is not the *reading* of the bytes but *the way you return the data*.

a ```Return``` statement or just putting the variable on the last line like you did, you tell PowerShell to 'unrolls' the return object before returning. this can be long for big byte arrays. The solution is to just add the [unary comma](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-7.3&viewFallbackFrom=powershell-7#comma-operator-) ```,``` before the returned $byteArray like this:

```powershell
  return ,$bytes
```

This will wrap the returned array inside another, one-element array. When an array is returned from a function, PowerShell 'unrolls' that and in this case, it unrolls the wrapper array, leaving the byte array inside.

Second option, you can use ```Write-Output -NoEnumerate``` Instead of return:


```powershell
  Write-Output $bytes -NoEnumerate
```

To fix the function above we would have this:

```powershell
  function Read-ByteArray([string]$Path) {
    $fs = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read)
    [byte[]]$file_bytes = [byte[]]::new($fs.Length)
    $Null = $fs.Read($file_bytes, 0, $fs.Length) 
    $fs.Close()
    $fs.Dispose()
    Write-Output $file_bytes -NoEnumerate
  }  
```


-------------------


Here's a test, with a file of 350MB

[Test Script](https://github.com/arsscriptum/PowerShell.Reddit.Support/blob/master/ReturnOptimization/Test.ps1)

![img](img/return.png)



```powershell

  function Convert-BytesToHumanReadable{
      [CmdletBinding(SupportsShouldProcess)]
      param (
          # Array of Bytes to use for CRC calculation
          [Parameter(Position = 0, ValueFromPipeline = $true)]
          [uint64]$TotalBytes
      )   
      $TotalKb =  ($TotalBytes / 1KB)
      $TotalMb =  ($TotalBytes / 1MB)
      $TotalGb =  ($TotalBytes / 1GB)
      [string]$TotalSizeInBytesStr = "{0:n2} Bytes" -f $TotalBytes
      [string]$TotalFolderSizeInKB = "{0:n2} KB" -f $TotalKb 
      [string]$TotalFolderSizeInMB = "{0:n2} MB" -f $TotalMb
      [string]$TotalFolderSizeInGB = "{0:n2} GB" -f $TotalGb
      [string]$res_str = ""
      if($TotalBytes -gt 1GB){
          $res_str =  $TotalFolderSizeInGB
      }elseif($TotalBytes -gt 1MB){
          $res_str =  $TotalFolderSizeInMB
      }elseif($TotalBytes -gt 1KB){
          $res_str =  $TotalFolderSizeInKB
      }else{
          $res_str =  $TotalSizeInBytesStr
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
```