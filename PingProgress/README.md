# Async Ping: Cailng Test-Connection though scriptblock Job

The goal was to add a progress bar while the ping are executing in the background


## File : ***PingTargets.ps1***

This file contains the scriptblock code for the network ping job as well as the custom ```Receive-Job``` function named ```Receive-PingJob``` that processes the job startup/outputprocessing andjob removal.

The job is staterd and is processed this way :

```
    # go in theporoject folder and the child folder "PingProcess"
    cd "PowerShell.Reddit.Support/PingProgress"
    # Execute the script ```PingTargets.ps1``` like so
    . .\PingTargets.ps1
```


### Receive-PingJob

1) Check if we stay in the processing loop:
2) Verify the Job state (Completed or not)
3) Verify if the job still has more data in the receie queue to be captured
4) Check the incoming receive queue size. If there are still items to be processed (dequeued) we are not done
5) The data outputed from jobs is a custom object encoded in json. We recreate the pscustomoject here. 
6) We then take each item separately and queue them in a FIFO queue for processing

The job is staterd and is processed this way :

```
    [scriptblock]$NetTestScriptBlock = [scriptblock]::create($NetTestScript) 

    $DefaultJobName = "NetworkPingJobs"
    $jobby = Start-Job -Name "$DefaultJobName" -ScriptBlock $NetTestScriptBlock -ArgumentList ("F:\Scripts\PowerShell.Reddit.Support\PingProgress\Computers.txt")
    Receive-PingJob -JobName "$DefaultJobName"
```


## File : ***progress/Initialize-NativeProgress.ps1***

This file contains the Cmdlets to handle the NativeProgressBar module initialization, de-initialization and processing.

### Some functions available in this file:

***Wrappers***
- Invoke-ReloadNativeProgressModule : A CmdLet that is a wrapper, to automate the module reloading from a single function call. There will be a check to see if the odule is still loaded in memory, an attempt to unload it and in case of failure, the powershell process will be terminated so that the new powershell session will not have a handle on the module.

***Main Cmdlets***
- Remove-NativeProgressModules : This CmdLet will unload all the handles for the NativeProgressModule, clear all the global variables and the module data structures that have been initialized.
- New-NativeProgressAssembly : This will create a copy of the assembly Dll file, it will load that Dll file and then import the module data. The module load time will be saved and the global variable containig the module information are created.

***Validation Cmdlets***
- Test-IsNativeProgressModuleLoaded : Checks for the different variable and dependencies loaded when the module is loaded. This CmdLet returns True if the module is unloaded. False otherwise.
- Test-NativeProgressModuleDependencies : Validates if the module dependencies are available.

***Helpers Cmdlets***
- New-ModuleObject : Helper function to take a PsObject and create a new PsObject with the same property names / values except the values are checked for exactitude: string whitespaces removed, eol, etc... asically a PsObject Cleaner
- Write-ModuleObjectDump : Helper function used in debugging to print out all the property values of an module PsObject
- Write-NativeProgressModuleStates : Helper function to print out the loaded module information (module path, name, etc and load time, assembly information, etc...)
***Getter***
- Get-NativeProgressModulesVariable : Get a module ***object instance*** based on the unique module assembly path. Useful when multiple modules loaded with thesame name.
- Get-NativeProgressModulesVariableIndex : Get a module ***object instance index*** based on the unique module assembly path. Useful when multiple modules loaded with thesame name.
***Update Cmdletv
- Update-VariablesFromLoadedModules : When there's a desync between the loaded modules and the module data structures, this CmdLet will update all the global variables and data structures with the latest modules information.




## File : ***Computers.txt***

Contains all the computer hostnames that will be tested by the network test job.


## Demo

I added my custom ascii progress bar for a reddit user

![DEMO](https://github.com/arsscriptum/PowerShell.Reddit.Support/blob/master/PingProgress/gif/demo.gif)