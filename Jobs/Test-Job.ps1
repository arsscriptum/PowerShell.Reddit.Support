
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


[CmdletBinding(SupportsShouldProcess)]
param()


. "$PSScriptRoot\Dependencies\AsciiProgressBar.ps1"

<#
    JOB SCRIPT
#>

$MyTestJobScript = {
      param([uint32]$JobDelay)
  
    try{

    function CheckJobCmd{
        try{
            [uint32]$Value = Get-Content -Path "$ENV:Temp\job_pipe_file" -Raw -Force -ErrorAction Ignore
            if($Null -eq $Value){ return 0 }
            # reset to 0
            Set-Content -Path "$ENV:Temp\job_pipe_file" -Value 0 -Force -ErrorAction Ignore
            return $Value
        }catch{ $Value = 0 }
        return $Value
    }



        [DateTime]$FinishTime = (get-Date).AddSeconds($JobDelay)
        [uint32]$UpdateDelay = 100
        while ([DateTime]::Now -lt $FinishTime){
            Start-Sleep -Milliseconds $UpdateDelay
            
            [timespan]$ts = $FinishTime - [DateTime]::Now
            $raw_percentage = (($JobDelay - ($ts.TotalSeconds))/$JobDelay)*100
            $percentage = [math]::Round($raw_percentage)

            if($percentage -lt 0) {$percentage = 0}
            if($percentage -gt 100) {$percentage = 100}
            $raw_elapsed_milliseconds =  $ts.TotalMilliseconds
            $elapsed_milliseconds = [math]::Round($raw_elapsed_milliseconds)
            $obj = [pscustomobject]@{
                percentage              = $percentage
                elapsed_milliseconds    = $elapsed_milliseconds
            }


            [uint32]$state = CheckJobCmd
            if($state -eq 1){
                $UpdateDelay = 2000
            }elseif($state -eq 2){
                $UpdateDelay = 250
            }
            [string]$str_output = $obj | ConvertTo-Json -Compress
            Write-Output($str_output)

            
        }
    }catch{
        Write-Error "$_"
    }finally{
        Write-verbose "done"
}}.GetNewClosure()

[scriptblock]$MyTestJobScriptBlock = [scriptblock]::create($MyTestJobScript) 



function Write-MyTitle{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True,Position=0, HelpMessage="Title")]
        [Alias('t')]
        [string]$Title,
        [Parameter(Mandatory = $False, HelpMessage="Clear")]
        [Alias('c')]
        [switch]$Clear
    )
    [int]$len = ([System.Console]::WindowWidth - 1)
    [string]$empty = [string]::new("=",$len)

    if($Clear){
        cls
    }
    $TitleLen = $Title.Length
    $posx = ([System.Console]::get_BufferWidth()/2) - ($TitleLen/2)
    Write-ConsoleExtended $empty -f Yellow
    Write-ConsoleExtended "$Title" -x $posx -y ([System.Console]::get_CursorTop()+1) -f Red
    Write-ConsoleExtended "`n$empty`n" -f Yellow ;



}


function Start-TestJob{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false)]
        [uint32]$JobDelay = 10,
        [Parameter(Mandatory=$false)]
        [bool]$ShowProgressBar = $True,
        [Parameter(Mandatory=$false)]
        [bool]$ShowDebug = $False
    )


    function SetJobCmd([uint32]$cmd){
        try{
            if(-not(Test-Path -Path "$ENV:Temp\job_pipe_file" -PathType Leaf)){
                $Null = New-Item -Path "$ENV:Temp\job_pipe_file" -ItemType File -Force -ErrorAction Ignore
            }
            Set-Content -Path "$ENV:Temp\job_pipe_file" -Value $cmd -Force -ErrorAction Ignore
        }catch{}
    }

    try{
        Start-AsciiProgressBar -EmptyChar ' ' -FullChar '=' -Size 30
        <#
            STARTING MY JOB
        #>
        $JobName = "my_test_job"
        get-job -name $JobName  -erroraction Ignore | remove-job -force -erroraction Ignore
        Write-Host "`n`nStart job `"$JobName`". Delay $JobDelay seconds. ShowProgressBar $ShowProgressBar" -f DarkYellow
        $jobby = Start-Job -Name $JobName -ScriptBlock $MyTestJobScriptBlock -ArgumentList ($JobDelay)
        $Transferring  = $True

        $JobState = (Get-Job -Name $JobName).State
        Write-verbose "JobState: $JobState"
        
        $ProgressTitle = "MODE: $JobName"
        
        
        if($ShowProgressBar -eq $True){
            Write-Progress -Activity $ProgressTitle -Status "start"
        }   
        
        <#
            GETTING STATUS UPDATES FROM MY JOB (reading variable from inside the job)
        #>
        while($Transferring){
            try{
                $JobState = (Get-Job -Name $JobName).State
                $Output = Receive-Job -Name $JobName

                Write-verbose "JobState: $JobState"
                if($JobState -eq 'Completed'){
                    $Transferring = $False
                    Get-Job $JobName | Remove-Job
                    return
                }

                # GETTING THE JSON STRING FROM THE JOB
                $line_out = $Output | Select-Object -Last 1

                # If there's no data received from job, no need to update.
                $UpdatedJobData = ($False -eq ([string]::IsNullOrEmpty($line_out)))
                
                if($UpdatedJobData -eq $True){
                    if($ShowDebug -eq $True){
                        $line_out 
                        continue
                    }

                    # PARSING THE JSON STRING
                    $job_variable_object = $line_out | ConvertFrom-Json

                    if($ShowProgressBar -eq $True){
                        [uint32]$progress_percentage = $job_variable_object.percentage
                   
                        $msg = "{0}% completed." -f $progress_percentage
                        Write-Progress -Activity $ProgressTitle -Status $msg -PercentComplete $progress_percentage
                    }else{
                        [uint32]$progress_percentage = $job_variable_object.percentage
                        [string]$col = 'Green'
                        if($progress_percentage -gt 90){ 
                            $col = 'DarkRed' 
                        }elseif($progress_percentage -gt 70){
                            $col = 'Red' 
                        }elseif($progress_percentage -gt 50){
                            $col = 'Yellow' 
                        }
                        $msg = "{0}% completed." -f $progress_percentage
                        Show-ActivityIndicatorBar -ForegroundColor $col
                        
                    }
                }
                Start-Sleep -Milliseconds 100
            }catch{
                Write-Error $_
            }
        }
        if($ShowProgressBar -eq $True){
            Write-Progress -Activity $ProgressTitle -Completed
        }else{
            Show-AsciiProgressBar 100 "Done"  -Clean
        }


    }catch{
        Write-Error "$_"
    }
}




Start-TestJob -ShowProgressBar $False
