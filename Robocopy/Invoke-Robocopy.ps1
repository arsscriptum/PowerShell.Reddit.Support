<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


function Write-RoboLog  {  
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [String]$Msg,
        [Parameter(Mandatory=$false)]
        [Alias('f', 'Foreground')]
        [String]$Color="Gray"
    )
    
    Write-RoboLog "$Msg " -f $Color
}


function Invoke-Robocopy {
    <#
    .SYNOPSIS
        Copy a directory to a destination directory using ROBOCOPY.
    .DESCRIPTION
        Backup a directory will copy all te files from the source directory but will not remove missing files
        on a second iteration, like a MIRROR/SYNC would   
    .DESCRIPTION
        Invoke ROBOCOPY to copy files, a wrapper.
    .PARAMETER Source
        Source Directory (drive:\path or \\server\share\path).
    .PARAMETER Destination
        Destination Dir  (drive:\path or \\server\share\path).
    .PARAMETER SyncType 
        One of the following operating procedures:
        'MIR'    ==> MIRror a directory tree (equivalent to /E plus /PURGE), delete dest files/dirs that no longer exist in source.
        'COPY'   ==> It will leave everything in destination, but will add new files fro source, usefull to merge 2 folders
        'NOCOPY' ==> delete dest files/dirs that no longer exist in source. do not copy new, keep same.
        Default  ==> MIRROR
    .PARAMETER Log
        Log File name
    .PARAMETER BackupMode
        copy files in restartable mode.; if access denied use Backup mode.
        Requires Admin privileges to add user rights.        
    .PARAMETER Test
        Simulation: dont copy (like what if, but will call Start-Process)        
    .EXAMPLE 
       Sync-Directories $dst $src -SyncType 'NOCOPY'
       Sync-Directories $src $dst -SyncType 'MIRROR' -Verbose
       Sync-Directories $src $dst -Test
#>

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Container) ){
                throw "The Path argument must be a Directory. Files paths are not allowed."
            }
            return $true 
        })]
        [Parameter(Mandatory=$true,Position=0)]
        [Alias('s', 'src')]
        [String]$Source,
        [Parameter(Mandatory=$true,Position=1)]
        [Alias('d', 'dst')]
        [String]$Destination,
        [Parameter(Mandatory=$false)]
        [Alias('t', 'type')]
        [ValidateSet('MIRROR', 'COPY', 'NOCOPY')]
        [string]$SyncType,        
        [Parameter(Mandatory=$false)]
        [Alias('l')]
        [String]$Log="",
        [Parameter(Mandatory=$false, HelpMessage="Num threads in multi-threaded copies with n threads (default 8)")]
        [ValidateRange(1,128)]
        [int]$Threads=8,
        [Parameter(Mandatory=$false, HelpMessage="Retries")]
        [int]$Retries=0,
        [Parameter(Mandatory=$false, HelpMessage="WaitOnError seconds")]
        [int]$WaitOnError=0,
        [Parameter(Mandatory=$false, HelpMessage="COPY ALL file info (equivalent to /COPY:DATSOU)")]
        [Alias('all')]
        [switch]$CopyAll,
        [Parameter(Mandatory=$false, HelpMessage="copy only existing (/XL)")]
        [switch]$CopyOnlyExisting,
        [Parameter(Mandatory=$false, HelpMessage="use Backup mode. Privilege SeRestorePrivilege/SeBackupPrivilege")]
        [Alias('b')]
        [switch]$BackupMode,
        [Parameter(Mandatory=$false, HelpMessage="use restartable mode")]
        [Alias('z')]
        [switch]$Restartable
    )

    try{

        # throw errors on undefined variables
        Set-StrictMode -Version 1

        if($BackupMode)
        {
            if(-not (Invoke-IsAdministrator)) { throw "Backup mode requires Admin privileges to change user rights" }
            Register-TokenManipulator

            Write-RoboLog "Enabling Privilege SeBackupPrivilege"             
            [void][TokenManipulator]::AddPrivilege("SeBackupPrivilege")
            
            Write-RoboLog "Enabling Privilege SeRestorePrivilege"             
            [void][TokenManipulator]::AddPrivilege("SeRestorePrivilege")           
        }
        # make sure the given parameters are valid paths

        if (-Not (Test-Path $Destination)) {
            if((ShouldCreateFolder $Destination) -eq $True){
                New-Item -Path $Destination -ItemType Directory -Force -ErrorAction Ignore | Out-null   
                
                Write-RoboLog "creating $Destination " -f Gray
            }else {
               throw "Destination Path $Destination Non-Existent"
            }   
        } 
        $Source  = Resolve-Path $Source
        $Destination = Resolve-Path $Destination
        $ROBOCOPY = (Get-Command 'robocopy.exe').Source
        Write-RoboLog "start sync '$Source' ==> '$Destination'"
        
        if($Log -ne ""){
            New-Item -Path $Log -ItemType File -Force -ErrorAction ignore | Out-Null
        }

        if (-Not (Test-Path -Type Container $Source))  { throw "not a container: $Source"  }
        if (-Not (Test-Path -Type Container $Destination)) { throw "not a container: $Destination" }
        if (-Not (Test-Path -Type Leaf $ROBOCOPY)) { throw "cannot find ROBOCOPY: $ROBOCOPY" }

        
        Write-RoboLog "/MT:$Threads /R:$Retries /W:$WaitOnError"

        $ArgumentList = "$Source $Destination /MT:$Threads /R:$Retries /W:$WaitOnError /BYTES /FP /X"

        if ($PSBoundParameters.ContainsKey('Verbose')) {
            
            Write-RoboLog "Verbose OUTPUT"             
            $ArgumentList += " /V"
        }

        if ($PSBoundParameters.ContainsKey('WhatIf')) {
            
            Write-RoboLog "WhatIf : Simulation; List only - don't copy, timestamp or delete any files."             
            $ArgumentList += " /L"
        }


        if ($PSBoundParameters.ContainsKey('SyncType')) {
            if($SyncType -eq 'MIRROR'){
                $ArgumentList += " /MIR" -f "Yellow"
                Write-RoboLog "MIRRORING : FILES WILL BE REMOVED OR ADDED TO BE N SYNC" 
            }elseif($SyncType -eq 'COPY'){
                $ArgumentList += " /COPY:DAT /E"
                Write-RoboLog "COPY ALL file info. copy subdirectories, including Empty ones." -f "Yellow"
            }elseif($SyncType -eq 'NOCOPY'){
                $ArgumentList += " /PURGE /NOCOPY "
                Write-RoboLog "NOCOPY" -f "Yellow"
            }else{
                throw "INVALID COPY TYPE"
            }
           
        }else{
            $ArgumentList += " /MIR "      
        }

        # Instantiate and start a new stopwatch
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        #  COPY ALL file info (equivalent to /COPY:DATSOU)
        if($CopyAll){
            Write-RoboLog "+ COPYALL (DATSOU)"
             $ArgumentList += " /COPYALL"
        }
        if($CopyOnlyExisting){
            Write-RoboLog "+ COPY ONLY EXISTING (/XL)"
             $ArgumentList += " /XL"
        }
        if($BackupMode){
            Write-RoboLog "+ BackupMode"
             $ArgumentList += " /B"
        }
        if($Restartable){
            Write-RoboLog "+ Restartable"
             $ArgumentList += " /Z"
        }
        if($Log -ne ""){
            Write-RoboLog "+ LOG:$Log"
            $ArgumentList += " /LOG:$Log"
        }
         Write-RoboLog "start sync $Source ==> $Destination`n`Multi-Threaded ($Threads threads)`n`t1 FAILURE ALLOWED`n`tCREATE DIRECTORY STRUCTURE`n" 
        $FNameOut = Join-Path "$ENV:TEMP"  "$(New-Guid).log"
        $FNameErr = Join-Path "$ENV:TEMP"  "$(New-Guid).log"
        $ProcessArguments = @{
            FilePath = $ROBOCOPY
            ArgumentList = $ArgumentList 
            Wait = $true 
            NoNewWindow = $true
            PassThru = $true
            RedirectStandardError  = $FNameErr
            RedirectStandardOutput = $FNameOut
        }
        Write-Verbose "Start-Process $ProcessArguments"

        $awnser = 'y'#Read-Host "Press `'y`' to go"
        
        $process = Start-Process @ProcessArguments
      
        $handle = $process.Handle # cache proc.Handle
        $null=$process.WaitForExit();

        # This will print out False/True depending on if the process has ended yet or not
        # Needs to be called for the command below to work correctly
        $null=$process.HasExited
        $ProcessExitCode = $process.ExitCode

        [int]$elapsedSeconds = $stopwatch.Elapsed.Seconds
        $stopwatch.Stop()

        $stdOut = Get-Content -Path $FNameOut -Raw
        $stdErr = Get-Content -Path $FNameErr -Raw
        if ([string]::IsNullOrEmpty($stdOut) -eq $false) {
            $stdOut = $stdOut.Trim()
        }
        if ([string]::IsNullOrEmpty($stdErr) -eq $false) {
            $stdErr = $stdErr.Trim()
        }
        
        Write-RoboLog "stdout`n$stdOut`n" -f DarkGray
        if($stdErr.Length -gt 0){
            Write-RoboLog "stdErr`n$stdErr`n" -f DarkRed
        }
        
        Write-RoboLog "COMPLETED IN $elapsedSeconds seconds" 
        if($Log -ne ""){
            $LogStr = Get-Content $Log -Raw
            
            Write-Verbose "$LogStr"
            Write-RoboLog "Log written to $Log" 
            Add-Content -path $Log -Value $stdOut
        }
        $returnCodeMessage = @{
            0x00 = "[INFO]: No errors occurred, and no copying was done. The source and destination directory trees are completely synchronized."
            0x01 = "[INFO]: One or more files were copied successfully (that is, new files have arrived)."
            0x02 = "[INFO]: Some Extra files or directories were detected. Examine the output log for details."
            0x04 = "[WARN]: Some Mismatched files or directories were detected. Examine the output log. Some housekeeping may be needed."
            0x08 = "[ERROR]: Some files or directories could not be copied (copy errors occurred and the retry limit was exceeded). Check these errors further."
            0x10 = "[ERROR]: Usage error or an error due to insufficient access privileges on the source or destination directories."
        }
        $returnCodeColor = @{
            0x00 = "DarkCyan"
            0x01 = "DarkCyan"
            0x02 = "DarkCyan"
            0x04 = "DarkRYellow"
            0x08 = "DarkRed"
            0x10 = "DarkRed"
        }
        if( $returnCodeMessage.ContainsKey( $ProcessExitCode ) ) {
            $Message = $returnCodeMessage[$ProcessExitCode]
            
            Write-RoboLog "$Message" -f $returnCodeColor[$ProcessExitCode]

        }
        else {
            for( $flag = 1; $flag -le 0x10; $flag *= 2 ) {
                if( $ProcessExitCode -band $flag ) {
                    $returnCodeMessage[$flag]
                    $Message = $returnCodeMessage[$flag]
                    
                    Write-RoboLog "$Message" -f DarkRed
                }
            }
        }

        if($BackupMode){
            if(-not (Invoke-IsAdministrator)) { throw "Backup mode requires Admin privileges to change user rights" }
            Register-TokenManipulator

            Write-RoboLog "Disabling Privilege SeBackupPrivilege"                   
            [void][TokenManipulator]::RemovePrivilege("SeBackupPrivilege")
            
            Write-RoboLog "Disabling Privilege SeRestorePrivilege"                   
            [void][TokenManipulator]::RemovePrivilege("SeRestorePrivilege")
        }

    }catch {
        Write-Error "$_"
    }
}
