

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
            Show-ExceptionDetails $_ -ShowStack
        }
    }




    function Receive-PingJob{
        [CmdletBinding(SupportsShouldProcess)]
        param(
            [Parameter(Mandatory=$false, HelpMessage="JobName", Position=0)]
            [string]$JobName="ConnTest"
        )

        try{
            Register-NativeProgressBar -Size 30
            $PipelineOutput = @()
            $Transferring = $True
            $JobState = (Get-Job -Name $JobName).State
            Write-verbose "JobState: $JobState"
            $RcvQueue = New-Object System.Collections.Queue
            $ProgressTitle = "MODE: PING $JobName"
            while($Transferring){
                Start-Sleep -Millisecond 500
                
                $JobData = Get-Job -Name $JobName
                $JobState = $JobData.State
                $JobHasMoreData = $JobData.HasMoreData 
                $RcvQueueCount = $RcvQueue.Count

                if( $JobState -eq 'Completed') {
                    if(( $RcvQueueCount -le 0) -And ($JobHasMoreData -eq $False)){
                        Write-verbose "STOPPING TRANSFERRING, EXIT NEXT LOOOP"
                        $Transferring = $False
                    }
                }
                $slog = @"
=====================================
JobState = $JobState
JobHasMoreData $JobHasMoreData
Transferring $Transferring
RcvQueueCount = $RcvQueueCount
=====================================
"@
                Write-verbose $slog
                $Output = Receive-Job -Name $JobName

                if($Output -ne $Null){
                    ForEach($data in $Output){
                        Write-verbose "Received New Data, Add to Queue"
                        $RcvQueue.Enqueue($data)
                    }
                }
                
                try{
                    Write-verbose "DeQueue Data"
                    $line_out = $RcvQueue.Dequeue()
                }catch{}                    
                
                if($line_out -eq $Null){
                    Write-verbose "DeQueue Data is null"
                    continue;
                }
                $progress = $line_out | ConvertFrom-Json
                $Hostname = $progress.ComputerName
                $Success = $progress.Success
                $progress_percentage = $progress.percentage

                $slog = @"
=====================================
Hostname = $Hostname
Success $Success
Percentage = $progress_percentage
=====================================
"@
                Write-verbose $slog
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
            Show-ExceptionDetails $_ -ShowStack
        }
    }




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

    $Loaded = Test-NativeProgressModuleDependencies
    if($Loaded -eq $False){
        New-NativeProgressAssembly -LoadModules
    }

    $DependenciesLoaded = Test-NativeProgressModuleDependencies
    if($DependenciesLoaded -eq $False){
        Write-Host "Fatal Error: Ne Dependencies, Exiting." -f Red
        return
    }

    Write-Host "`n`n"
    Write-Host "================================================================" -f DarkYellow
    Write-Host "                      PRESS A KEY TO START                      " -f DarkRed
    Write-Host "================================================================" -f DarkYellow

    Read-Host " . "
    cls
    [scriptblock]$NetTestScriptBlock = [scriptblock]::create($NetTestScript) 

    $jobby = Start-Job -Name "ConnTest" -ScriptBlock $NetTestScriptBlock -ArgumentList ("F:\Scripts\PowerShell.Reddit.Support\PingProgress\Computers.txt")
    Receive-PingJob -JobName "ConnTest"



