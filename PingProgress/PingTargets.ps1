
    # ==========================================================================================
    # SIMPLE SCRIPT BLOCK IMPLEMENTING THE NETWORK CONNECTION TEST LOGIC
    # REFER TO SECTION 3 AT THE BOTTOM OF THIS FILE TO VIEW HOW THIS SCRIPT IS USED
    # ==========================================================================================

    $NetTestScript = {
        Param (
            [parameter(Mandatory = $True, Position = 0)]
            [string]$Path
        )

        try{
            $Computers = Get-Content "F:\Scripts\PowerShell.Reddit.Support\PingProgress\Computers.txt"
            
            $i = 0
            foreach ($computer_name in  $Computers){
                $ping_result = Test-Connection $computer_name -IPv4 -Count 1 -TimeoutSeconds 5 -Delay 2 -Quiet
                
                $percentage = [math]::Round(++$i / $($Computers.Count) * 100)
                $obj = [pscustomobject]@{
                    percentage   = $percentage
                    ComputerName = $computer_name
                    Success      = $ping_result
                }
                [string]$str_output = $obj | ConvertTo-Json
                Write-Output($str_output)
                    
            }

        }catch{
            Write-Error "$_"
        }
    }


    # ==========================================================================================
    # CUSTOM RECEIVE-JOB FUNCTION IMPLEMENTED TO PROCESS THE NETWORK CONNECTION TEST JOBS
    # ==========================================================================================


    function Receive-PingJob{
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory=$false, HelpMessage="JobName", Position=0)]
            [string]$JobName="NetworkPingJobs"
        )

        try{
            Register-NativeProgressBar -Size 30
            $PipelineOutput = @()
            $ReceivingPingData = $True

            Write-verbose "JobState: $JobState"
            $RcvQueue = New-Object System.Collections.Queue
            $ProgressTitle = "MODE: PING $JobName"
            while($ReceivingPingData){
                Start-Sleep -Millisecond 500
                
                $JobData = Get-Job -Name $JobName
                $JobState = $JobData.State
                $JobHasMoreData = $JobData.HasMoreData 
                $RcvQueueCount = $RcvQueue.Count
                
                # Check if we stay in the processing loop:
                # - Verify the Job state (Completed or not)
                # - Verify if the job still has more data in the receie queue to be captured
                # - Check the incoming receive queue size. If there are still items to be processed (dequeued) we are not done
                if( $JobState -eq 'Completed') {
                    if(( $RcvQueueCount -le 0) -And ($JobHasMoreData -eq $False)){
                        Write-verbose "STOPPING TRANSFERRING, EXIT NEXT LOOOP"
                        $ReceivingPingData = $False
                    }
                }

                # This gets data outputed from the jobs and store them in an array temporarly
                $Output = Receive-Job -Name $JobName

                # We then take each item separately and queue them in a FIFO queue for processing
                if($Output -ne $Null){
                    ForEach($data in $Output){
                        Write-verbose "Received New Data, Add to Queue"
                        $RcvQueue.Enqueue($data)
                    }
                }
                
                # ======================
                # PROCESSING STARTS HERE
                try{
                    Write-verbose "DeQueue Data"
                    $line_out = $RcvQueue.Dequeue()
                }catch{}                    
                
                if($line_out -eq $Null){
                    Write-verbose "DeQueue Data is null"
                    continue;
                }

                # The data outputed from jobs is a custom object encoded in json. We recreate the pscustomoject here. 
                $progress = $line_out | ConvertFrom-Json

                $Hostname = $progress.ComputerName
                $Success = $progress.Success
                $progress_percentage = $progress.percentage

                if([string]::IsNullOrEmpty($Hostname)){
                    Write-verbose "Hostname: NULL, continue"
                    continue;
                }

                if($progress_percentage -eq $Null) {$progress_percentage = 0}
                if($progress_percentage -lt 0) {$progress_percentage = 0}
                if($progress_percentage -gt 100) {$progress_percentage = 100}
                $ProgressMessage = "Completed {0} %" -f $progress_percentage

                $Col1_Len = 25
                $Col2_Len = 10
                $Diff1 = $Col1_Len - $Hostname.Length 
                [string]$spaces = [string]::new(' ', $Diff1)
                $HostnameWide = $Hostname.Insert($Hostname.Length,$spaces)

                $Diff2 = $Col2_Len - 7
                [string]$spaces = [string]::new(' ', $Diff2)
                if($Success){ $SuccessStr = "Success" ; $color = "DarkGreen" }else{ $SuccessStr = "Failure" ; $color = "DarkRed" }
                $SuccessWide = $SuccessStr.Insert($SuccessStr.Length,$spaces)

                $PipelineOutput += "$HostnameWide`t$SuccessWide`t( $progress_percentage % )"

                Write-NativeProgressBar $progress_percentage $ProgressMessage 50 2 "White" "DarkGray"
            }
            
            Remove-Job -Name $JobName
            cls
            $PipelineOutput
        }catch{
            Write-Error "$_"
        }
    }



    # ==========================================================================================
    # SECTION 1 : IMPORT SCRIPTS FOR PROGRESS BAR
    # ==========================================================================================

    Write-Host "================================================================" -f DarkYellow
    Write-Host "                        IMPORTING SCRIPTS                       " -f DarkRed
    Write-Host "================================================================" -f DarkYellow

    $FatalError = $False
    try{
        $InitScript = "$PSScriptRoot\progress\Initialize-NativeProgress.ps1"
       
        if(Test-Path $InitScript){
            . "$InitScript"
            Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
            Write-Host "Initialization Script from `"$InitScript`""
        }else{
            throw "No such file `"$InitScript`""
        }
       
    }catch{
        Write-Error "Initialization Error. $_"
        $Script:FatalError = $True
    }

    if($Script:FatalError){
        Write-Host "Fatal Error: Exiting." -f Red
        return
    }

    cls

    # ==========================================================================================
    # SECTION 2 : LOAD CUSTOM MODULE FOR PROGRESS BAR
    # ==========================================================================================

    Write-Host "================================================================" -f DarkCyan
    Write-Host "                           NOW LOADING                          " -f Magenta
    Write-Host "                    THE PROGRESS BAR MODULE                     " -f Magenta
    Write-Host "                      NATIVE DEPENDENCIES                       " -f Magenta
    Write-Host "================================================================" -f DarkCyan

    # Global boolean flag set after initializAtion
    [bool]$NativeModuleTestInitialized = (Get-Variable -Name "NativeModuleTestInitialized" -ValueOnly -Scope Global -ErrorAction Ignore) -ne $Null
    # A Cmdlet pointer, that is availabl when the required module is loaded
    $FunctionPtr = (Get-Command "Write-NativeProgressBar" -ErrorAction Ignore)
    [bool]$ModuleFunctionValid = $FunctionPtr -ne $Null
    # Checking both flags defined above. We are loaded when both are in agreementg.
    [bool]$ModuleInitialized = ($NativeModuleTestInitialized -eq $True) -And ($ModuleFunctionValid -eq $True)

    Write-Host "`n"
    Write-Host "================================================================" -f DarkCyan
    Write-Host "                   VERIFICATION OF CURRENT STATE        " -f DarkYellow
    Write-Host "================================================================" -f DarkCyan
    Write-Host "Native Module Test Initialized    = $NativeModuleTestInitialized" -f DarkCyan
    Write-Host "Write-NativeProgressBar Valid     = $ModuleFunctionValid" -f DarkCyan
    Write-Host "Initialization Flag + Function    = $ModuleInitialized" -f DarkRed
    Write-Host "`n"


    if($ModuleInitialized -eq $False){
        New-NativeProgressAssembly -LoadModules
    }

    $DependenciesLoaded = Test-NativeProgressModuleDependencies
    if($DependenciesLoaded -eq $False){
        Write-Host "Fatal Error: Ne Dependencies, Exiting." -f Red
        return
    }





    # ==========================================================================================
    # SECTION 3 : ACTUAL PING CODE - THE CONNECTION TEST
    # ==========================================================================================

    Write-Host "`n`n"

    Write-Host "`t`t`t`t`tPRESS A KEY TO START" -f DarkRed
    Write-Host "`t`t`t`t`t--------------------" -f DarkRed

    Read-Host " . "
    cls
    [scriptblock]$NetTestScriptBlock = [scriptblock]::create($NetTestScript) 

    $DefaultJobName = "NetworkPingJobs"
    $jobby = Start-Job -Name "$DefaultJobName" -ScriptBlock $NetTestScriptBlock -ArgumentList ("F:\Scripts\PowerShell.Reddit.Support\PingProgress\Computers.txt")
    Receive-PingJob -JobName "$DefaultJobName"


