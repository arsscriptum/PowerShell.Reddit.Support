<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


[CmdletBinding(SupportsShouldProcess)]
param()


function Save-OnlineFile{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True, Position = 0)]
        [string]$Uri,
        [Parameter(Mandatory=$True, Position = 1)]
        [ValidateScript({
            if( ($_ | Test-Path) ){
                throw "File or folder already exist. Please enter a non-existant file path."
            }
            return $true 
        })]
        [string]$Path
    )
   try{
        new-item -path $Path -ItemType 'File' -Force | Out-Null
        remove-item -path $Path -Force | Out-Null
        $Res = $Null
      
        $request = [System.Net.HttpWebRequest]::Create($Url)
        $request.PreAuthenticate = $false
        $request.Method = 'GET'
        $request.Headers = New-Object System.Net.WebHeaderCollection
        $request.Headers.Add('User-Agent','Mozilla/5.0')

        # Cache-Control : Note that no-cache does not mean "don't cache". no-cache allows caches to store a response but requires 
        # them to revalidate it before reuse. If the sense of "don't cache" that you want is actually
        # "don't store", then no-store is the directive to use.
        $request.Headers.Add('Cache-Control', 'no-store')
        # 15 second timeout
        $request.set_Timeout(15000)

        # Cache Policy : no cache
        $request.CachePolicy                  = New-Object Net.Cache.RequestCachePolicy([Net.Cache.RequestCacheLevel]::NoCacheNoStore)

        # create the Stream, FileStream and WebResponse objects
        [System.Net.WebResponse]$response     = $request.GetResponse()
        [System.IO.Stream]$responseStream     = $response.GetResponseStream()
        [System.IO.FileStream]$targetStream   = [System.IO.FileStream]::new($Path, [System.IO.FileMode]::Create)

        $buffer                               = new-object byte[] 10KB
        $count                                = $responseStream.Read($buffer,0,$buffer.length)

        while ($count -gt 0){
            Start-Sleep -Milliseconds 5
           $targetStream.Write($buffer, 0, $count)
           $count = $responseStream.Read($buffer,0,$buffer.length)
        }

        if(Test-Path $Path){
            $FileSize = (Get-Item $Path).Length
            Write-Verbose "Downloaded file `"$Path`" ($FileSize bytes)"
        }

        $targetStream.Flush()
        $targetStream.Close()
        $targetStream.Dispose()
        $responseStream.Dispose()

        $Res = $Path
    }catch{
        Write-Error "$_"
    }
    return $Res 
}


function Install-HtmlAgilityPack { 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "Folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Container) ){
                throw "The Path argument must be a Directory. Files paths are not allowed."
            }
            return $true 
        })]
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Path,
        [Parameter(Mandatory=$False)]
        [string]$Version = '1.11.48'
    )

    $PkgName = 'HtmlAgilityPack'
   
    $Url = "https://www.nuget.org/api/v2/package/{0}/{1}" -f $PkgName, $Version
    $TmpPath = "$ENV:Temp\{0}" -f ((Get-Date -UFormat %s) -as [string])
    Write-Verbose "Creating Temporary path `"$TmpPath`"" 
    $Null = New-Item -Path "$TmpPath" -ItemType Directory -Force -ErrorAction Ignore
    $DownloadedFilePath = "{0}\{1}.{2}.zip" -f $TmpPath, $PkgName, $Version

    Write-Verbose "Saving `"$Url`" `"$DownloadedFilePath`" ... " 
    $Results = Save-OnlineFile -Uri $Url -Path "$DownloadedFilePath"
    if($Results -eq $Null) {  throw "Error while fetching package $Url" }

    Write-Verbose "Extracting `"$DownloadedFilePath`" ... " 
    Expand-Archive $Results $TmpPath -Force
    $dotNetTarget = "netstandard2.0"
    $DownloadedAssembly = "{0}\lib\{1}\{2}.dll" -f $TmpPath, $dotNetTarget, $PkgName

    Write-Verbose "Copying `"$DownloadedAssembly`" to `"$Path`""
    $InstalledLib = Copy-Item "$DownloadedAssembly" "$Path" -Force -ErrorAction Stop -Passthru
    Write-Verbose "Deleting Temporary path `"$TmpPath`"" 
    #remove-item -path $TmpPath -Force -Recurse | Out-Null

    $InstalledLib
}

$InstallLocation = "$PSScriptRoot\lib"
new-item -path $InstallLocation -ItemType 'Directory' -Force | Out-Null
Install-HtmlAgilityPack $InstallLocation
