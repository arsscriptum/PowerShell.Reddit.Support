


<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


[CmdletBinding(SupportsShouldProcess)]
param()


<#
    .SYNOPSIS
        Install-PsLoggedOn 
    .DESCRIPTION
        Install the PsLoggedOn Program Locally

        The installation is done automatically if the file is not locacted on the computer. It is very fast. 

        1. Downloads the ```https://download.sysinternals.com/files/PSTools.zip``` packages from sysinternals.
        2. Unpack the files to TEMP folder
        3. Copy the PsLoggedOn.exe Program to Destination folder.

#>
function Install-PsLoggedOn { 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$False)]
        [string]$DestinationPath
    )
    begin{
        if([string]::IsNullOrEmpty($DestinationPath)){
            $DestinationPath = "{0}\psloggedon" -f "$PSScriptRoot"
        }
        if(-not(Test-Path -Path "$DestinationPath" -PathType Leaf)){ 
            $Null = New-Item -Path "$DestinationPath" -ItemType Directory -Force -ErrorAction Ignore
        }
        
    }
    process{
      try{
        $Url = "https://download.sysinternals.com/files/PSTools.zip"
        $TmpPath = "$ENV:Temp\{0}" -f ((Get-Date -UFormat %s) -as [string])
        Write-Verbose "Creating Temporary path `"$TmpPath`"" 
        $Null = New-Item -Path "$TmpPath" -ItemType Directory -Force -ErrorAction Ignore
        $DownloadedFilePath = "{0}\PSTools.zip" -f $TmpPath

        Write-Verbose "Saving `"$Url`" `"$DownloadedFilePath`" ... " 
        $ppref = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        $Results = Invoke-WebRequest -Uri $Url -OutFile $DownloadedFilePath -PassThru
        $ProgressPreference = $ppref 
        if($($Results.StatusCode) -ne 200) {  throw "Error while fetching package $Url" }

        Write-Verbose "Extracting `"$DownloadedFilePath`" ... " 
        
        $Files = Expand-Archive -Path $DownloadedFilePath -DestinationPath $TmpPath -Force -Passthru | Where Name -Match "PsLoggedOn"
        ForEach($f in $Files.Fullname){
            Copy-Item -Path "$f" -Destination "$DestinationPath" -Force
        }
        $InstalledFilePath = "{0}\PsLoggedon64.exe" -f $DestinationPath
        if(-not(Test-Path -Path "$InstalledFilePath" -PathType Leaf)){ throw "install error" }
        $InstalledFilePath
      }catch{
        throw $_
      }
    }
}



<#
    .SYNOPSIS
        Search-PsLoggedOnApp
    .DESCRIPTION
        Search-PsLoggedOnApp

        1. Look in Path (Get-Command)
        2. Look in current folder
        3. Look in ProgramFiles and TEMP folders
#>
function Search-PsLoggedOnApp { 
    [CmdletBinding(SupportsShouldProcess)]
    param()

    begin{
        
        [string]$CurrentPath = "$PSScriptRoot"
        $SearchLocations = @("$CurrentPath", "$ENV:Temp", "$ENV:ProgramFiles")

    }
    process{
      try{
        $PsLoggedon64Exe = ""
        $Cmd = Get-Command "PsLoggedon64.exe"
        if($Cmd -ne $Null){
            $PsLoggedon64Exe = $Cmd.Source
            Write-Verbose "Found `"$PsLoggedon64Exe`" in PATH"
        }else{
            [string[]]$SearchResults = ForEach($dir in $SearchLocations){
                Write-Verbose "Searching in `"$dir`""
                Get-ChildItem -Path "$dir" -File -Recurse -Filter "PsLoggedon64.exe" -Depth 2 -ErrorAction Ignore | Select -ExpandProperty Fullname
            }
            $SearchResultsCount = $SearchResults.Count
            if($SearchResultsCount -gt 0){
                $PsLoggedon64Exe = $SearchResults[0]
                Write-Verbose "Found $SearchResultsCount Results. Using `"$PsLoggedon64Exe`""
            }
        }
        
        $PsLoggedon64Exe
      }catch{
        throw $_
      }
    }
}


<#
    .SYNOPSIS
        Get-LoggedOnUsers
    .DESCRIPTION
        Check if PsLogged on is installed, if not install it.
        Get LoggedOn Users using PsLoggedOn program
        PArse the output in PsCustom Objects

#>
function Get-LoggedOnUsers { 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position = 0, Mandatory=$false, ValueFromPipeline=$true, HelpMessage="Computer Name")]
        [string]$ComputerName
    )
    begin{
        # was a remote computer specified ?
        $ComputerSpecified = ($False -eq ([string]::IsNullOrEmpty($ComputerName)))
        Write-Verbose "ComputerSpecified `"$ComputerSpecified`""
        if($ComputerSpecified -eq $True){
            # if a remote machine was specified, try to connect to it first, if it failes, no need to go further...
            $ComputerAvailable =Test-Connection -TargetName  "$ComputerName" -Ping -Count 1 -IPv4 -Quiet
            Write-Verbose "Connecting to `"$ComputerName`" - ComputerAvailable $ComputerAvailable"
            if(-not($ComputerAvailable)){ throw "canot connect to `"$ComputerName`""}
        }
        # Search fot PSLoggedOn program...
        [string]$PsLoggedon64Exe = Search-PsLoggedOnApp
        if([string]::IsNullOrEmpty($PsLoggedon64Exe)){
            # Install it if no existant
            Write-Verbose "Canot find PsLoggedOn, Installing PsLoggedOn"
            $PsLoggedon64Exe = Install-PsLoggedOn
            Write-Verbose "Using `"$PsLoggedon64Exe`""
        }
        if(-not(Test-Path -Path "$PsLoggedon64Exe" -PathType Leaf)){ 
            throw "cannot find psloggedon"
        }
    }
    process{
      try{
        # Execute the program and parse the output
        [System.Collections.ArrayList]$Users = [System.Collections.ArrayList]::new()
        if($ComputerSpecified -eq $True){
            [string[]]$Output = &"$PsLoggedon64Exe" "\\$ComputerName" "-nobanner"
        }else{
            [string[]]$Output = &"$PsLoggedon64Exe" "-nobanner"
        }
        [uint32]$OutputCount = $Output.Count
        if($OutputCount -le 2){ throw "invalid data" }
        ForEach($line in $Output){
            if($line -match '^(?<FourSpaces>( ){4})'){
                $trimmed_line = $line.TrimStart()
                [string[]]$substr = $trimmed_line.Split("`t")
                [String]$DateStr = $substr[0].Trim()
                Write-Verbose "DateStr `"$DateStr`""
                
                [string]$UserName = $substr[$substr.Count - 1].Trim()
                Write-Verbose "UserName `"$UserName`""
                if(-not([string]::IsNullOrEmpty($UserName))){
                    [PsCustomObject]$o = [PsCustomObject]@{
                        LoginTime = $DateStr
                        UserName = $UserName
                    }
                    [void]$Users.Add($o)
                }   
            }
        }
        $Users
       
      }catch{
        throw $_
      }
    }
}



function Test-GetLoggedOnUsers { 
    [CmdletBinding(SupportsShouldProcess)]
    param()

    process{
      try{


        Write-Host "------------------------------------------------" -f DarkRed
        Write-Host "            DETERMINING USERS LOGONS            "  -f DarkYellow
        Write-Host "`n`nRunning Get-LoggedOnUsers..."  -f DarkCyan
        $local = Get-LoggedOnUsers

        $CsvData = $local | ConvertTo-Csv
        
        $ExportPath = "{0}\export" -f "$PSScriptRoot"
        $Null = New-Item -Path "$ExportPath" -ItemType Directory -Force -ErrorAction Ignore
        $ExportFilePath = "{0}\LocalUsers.csv" -f $ExportPath
        Write-Host "Exporting Local LoggedOn Users to `"$ExportFilePath`""  -f DarkCyan
        Set-Content -Path "$ExportFilePath" -Value $CsvData -Force -ErrorAction Ignore

        
        Write-Host "`n`nGet-LoggedOnUsers `"DESKTOP-JIRMI11`""  -f Magenta
        

        Write-Host "Retrieving Remote LoggedOn Users..."  -f Magenta
        $RemoteUsers = Get-LoggedOnUsers "DESKTOP-JIRMI11" 
        $CsvData = $local | ConvertTo-Csv
        
        $ExportPath = "{0}\export" -f "$PSScriptRoot"
        $Null = New-Item -Path "$ExportPath" -ItemType Directory -Force -ErrorAction Ignore
        $ExportFilePath = "{0}\RemoteUsers.csv" -f $ExportPath
        Write-Host "Exporting Remote LoggedOn Users to `"$ExportFilePath`""  -f Magenta
        Set-Content -Path "$ExportFilePath" -Value $CsvData -Force -ErrorAction Ignore
        Write-Host "Done!" -f Green
       
      }catch{
        throw $_
      }
    }

}

