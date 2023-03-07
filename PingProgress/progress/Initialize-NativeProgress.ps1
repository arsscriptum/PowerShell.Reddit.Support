
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)] 
    [switch]$ReloadModule,
    [Parameter(Mandatory = $false)] 
    [switch]$LoadOnce
)

$Script:RootPath = (Resolve-Path "$PSScriptRoot\..").Path
$Script:TmpPath = Join-Path "$PSScriptRoot" "tmp"



function Write-ModuleObjectDump{

    [CmdletBinding(SupportsShouldProcess)]
    param(    
        [Parameter(Mandatory=$true, HelpMessage="ModuleObject")]
        [System.Object]$ModuleObject
    ) 
    Write-Host "`n`n==================================================================" -f DarkYellow
    Write-Host "DUMP of $($ModuleObject.Name)" -f DarkRed

    try{
        $ModuleObject | Get-Member -Type properties | foreach name | 
            foreach { 
                $NameStr = $_ 
                [string]$ValueStr = $($ModuleObject."$NameStr")

                Write-Host "`t- $NameStr = " -n -f DarkCyan
                Write-Host "`"$ValueStr`"" -f DarkYellow
        }

        Write-Host "==================================================================" -f DarkYellow
    }catch [Exception]{
        Write-Error "$_"
    }
    return $null
}


function New-ModuleObject{

    [CmdletBinding(SupportsShouldProcess)]
    param(    
        [Parameter(Mandatory=$true, HelpMessage="ModuleObject")]
        [System.Object]$ModuleObject,
        [Parameter(Mandatory=$false)]
        [switch]$KeepOnlyNotNull
    ) 
  
    try{
        
        $obj = New-Object -TypeName "System.Object"

        $ModuleObject | Get-Member -Type properties | foreach name | 
            foreach { 
                $NameStr = $_ 
                [string]$ValueStr = $($ModuleObject."$NameStr")

                Write-Verbose "ORIGINAL`n$NameStr = `"$ValueStr`""
                $NameStr = $NameStr.Trim()
                if([string]::IsNullOrEmpty($ValueStr) -eq $False){
                    [string]$ValueStr = [string]$ValueStr.Trim() 
                }

                $AddProperty = $False
                
                if($KeepOnlyNotNull){
                    $AddProperty = [String]::IsNullOrEmpty($ValueStr) -eq $False
                    Write-Verbose "KeepOnlyNotNull. $NameStr = `"$ValueStr`". AddProperty $AddProperty"
                }else{
                    Write-Verbose "SETTING`n$NameStr = `"$ValueStr`""
                    Add-Member -InputObject $obj -MemberType NoteProperty -Name "$NameStr" -Value "$ValueStr"
                }

            }
        


        $obj
    }catch [Exception]{
        Write-Error "$_"
    }
    return $null
}

function Write-NativeProgressModuleStates{

    [CmdletBinding(SupportsShouldProcess)]
    param() 
  
    try{

        Write-Host "==============================" -f DarkCyan
        Write-Host "List Previously Loaded Modules" -f DarkGray
        $PreviouslyLoadedModules =  Get-Module -Name "*NativeProgress*" 
        $PreviouslyLoadedModulesCount = $PreviouslyLoadedModules.Count
        $NativeProgressModulesCount = 0
        [System.Collections.ArrayList]$NativeProgressModules = Get-Variable -Name "NativeProgressModules" -ValueOnly -Scope Global -ErrorAction Ignore
        if($NativeProgressModules -ne $Null){
            $NativeProgressModulesCount = $NativeProgressModules.Count 
        }

        Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
        Write-Host "Loaded NativeProgress Modules : $PreviouslyLoadedModulesCount" -f DarkYellow
        Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
        Write-Host "Native Progress Modules Count : $NativeProgressModulesCount" -f DarkYellow

        Write-Host "`nNative Progress Modules Variable" -f DarkCyan
        Write-Host "================================" -f DarkGray
        if($NativeProgressModules -ne $Null){
            ForEach($npmod in $NativeProgressModules){
                $NowTime = Get-Date 
                $NowTimeSeconds = ConvertTo-CTime($NowTime)
                $Name = $npmod.Name
                $LoadTime = $npmod.LoadTime 
                $SecondsSinceLoaded = $NowTimeSeconds - $LoadTime
                $AssemblyLocation = $npmod.AssemblyLocation 
                [string]$LogStr = "`t- Module {0}[{1}] Loaded since {2} minutes" -f $Name,  $AssemblyLocation, ([math]::Round($SecondsSinceLoaded/60))
                Write-Host $LogStr -f DarkGreen
            }
        }
        if($PreviouslyLoadedModulesCount -gt 0){
            Write-Host "`nLoaded NativeProgress Modules" -f DarkCyan
            Write-Host "=============================" -f DarkGray
            ForEach($npmod in $PreviouslyLoadedModules){
                $NowTime = Get-Date 
                $NowTimeSeconds = ConvertTo-CTime($NowTime)
                $AssemblyLocation = $npmod.AssemblyLocation 
                $Basename = (Get-Item "$AssemblyLocation").Basename
                $LastWriteTime = (Get-Item "$AssemblyLocation").LastWriteTime
                $LoadTime = $npmod.LoadTime 
                $SecondsSinceLoaded = $NowTimeSeconds - $LoadTime
                
                [string]$LogStr = "`t- Module {0} Created on {1}, Loaded since {2} minutes.`n`t  {3}" -f $Basename, $LastWriteTime, ([math]::Round($SecondsSinceLoaded/60)), $AssemblyLocation 
                Write-Host $LogStr -f Yellow
                
            }
        }
    }catch [Exception]{
        Write-Error "$_"
    }
    return $null
}


function Remove-NativeProgressModules{

    [CmdletBinding(SupportsShouldProcess)]
    param() 
  
    try{

        Write-Host "================================================================" -f DarkYellow
        Write-Host "                           CleanUp                              " -f DarkRed
        Write-Host "================================================================" -f DarkYellow
        Write-Host "Unloading all previously loaded modules matching `"*NativeProgress*`""
        Get-Module -Name "*NativeProgress*" | Remove-Module -Force
        $Script:RootPath = (Resolve-Path "$PSScriptRoot\..").Path
        $Script:TmpPath = Join-Path $Script:RootPath "tmp"
        $Script:ErrorOccured = $False
        try{
            if(Test-Path "$Script:TmpPath" -PathType Container){
                Remove-Item "$Script:TmpPath" -Recurse -Force -ErrorAction Stop -ErrorVariable DeleteError | Out-Null
                Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
                Write-Host "Deleting directory `"$Script:TmpPath`"" -f Gray
            }else{
                Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
                Write-Host "Directory `"$Script:TmpPath`" CLEARED" -f Yellow
            }
        }catch{
            Write-Host "`t[ERROR] " -n -f DarkRed
            Write-Host "$_" -f DarkYellow
            $Script:ErrorOccured = $True
        }
        try{
            $NativeProgressModules = Get-Variable -Name "NativeProgressModules" -ValueOnly -Scope Global -ErrorAction Stop
            $NativeProgressModulesCount = $NativeProgressModules.Count 
            Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
            Write-Host "Clearing  `"NativeProgressModules`" variable. Count of $NativeProgressModulesCount" -f Gray
            $NativeProgressModules.Clear()
        }catch{
            $NativeProgressModulesCount = $Null
        }

        [System.Collections.ArrayList]$NativeProgressModules = [System.Collections.ArrayList]::new()
        Set-Variable -Name "NativeProgressModules" -Value $NativeProgressModules -Option AllScope -Force -Visibility Public -Scope Global -ErrorAction Ignore
        Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
        Write-Host "Clear and reinit variable `"NativeProgressModules`"" -f DarkCyan
        
    }catch [Exception]{
        Write-Error "$_"
    }
    return $null
}


function Test-NativeProgressModuleUnloaded{

    [CmdletBinding(SupportsShouldProcess)]
    param() 
  
    try{
        $Script:UnloadCompleted = $True
        $LoadedModules = Get-Module -Name "*NativeProgress*"
        $LoadedModulesCount = $LoadedModules.Count

        if($LoadedModulesCount -gt 0){
            Write-Host "[ERROR] " -n -f DarkRed
            Write-Host "Still $LoadedModulesCount Modules loaded!" -f DarkYellow
            $Script:UnloadCompleted = $False
        }
        $Script:RootPath = (Resolve-Path "$PSScriptRoot\..").Path
        $Script:TmpPath = Join-Path $Script:RootPath "tmp"
        $Script:ErrorOccured = $False

        [System.Collections.ArrayList]$ItemsToDelete = [System.Collections.ArrayList]::new()
        if(Test-Path "$Script:TmpPath" -PathType Container){
            [void]$ItemsToDelete.Add($Script:TmpPath)
            $Dlls = (Get-ChildItem -Path "$Script:TmpPath" -File -Filter "*.dll" -Recurse).Fullname
            ForEach($file in $Dlls){
                [void]$ItemsToDelete.Add($file)
            }
        }
        $ItemsToDeleteCount = $ItemsToDelete.Count

        if($ItemsToDeleteCount -gt 0){
            Write-Host "[ERROR] " -n -f DarkRed
            Write-Host "Still $ItemsToDeleteCount Iems to delete!" -f DarkYellow
            ForEach($item in $ItemsToDelete){
                Write-Host "`t[$item]" -f Gray
            }
            $Script:UnloadCompleted = $False
        }

        [System.Collections.ArrayList]$NativeProgressModules = Get-Variable -Name "NativeProgressModules" -ValueOnly -Scope Global -ErrorAction Ignore
        if($NativeProgressModules -ne $Null){
            $NativeProgressModulesCount = $NativeProgressModules.Count 
            if($NativeProgressModulesCount -gt 0){
                $Script:UnloadCompleted = $False
                Write-Host "`"NativeProgressModules`" variable. Count of $NativeProgressModulesCount" -f Gray
            }
            
        }
        return $Script:UnloadCompleted
    }catch [Exception]{
        Write-Error "$_"
    }
    return $Script:UnloadCompleted
}


function New-NativeProgressAssembly{

  
    [CmdletBinding(SupportsShouldProcess)]
    param(    
        [Parameter(Mandatory=$false, HelpMessage="NoLoad")]
        [Switch]$LoadModules
    ) 
  
    try{

        Write-Host "================================================================" -f DarkYellow
        Write-Host "                     Create New Assembly                        " -f DarkRed
        Write-Host "================================================================" -f DarkYellow


        [string]$destDll = "{0}\{1}\{2}" -f "$Script:TmpPath" , (get-date -UFormat "%H%M%S"), "NativeProgressBar.dll"
        Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
        Write-Host "Creating New Dll file `"$destDll`""
        New-Item "$destDll" -ItemType file -Force -ErrorAction Ignore | Out-Null
        Remove-Item "$destDll" -Recurse -Force -ErrorAction Ignore | Out-Null
        Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
        Write-Host "Copy DLL content `"$PSScriptRoot\lib\NativeProgressBar.dll`" ==> `"$destDll`""
        $NewDll = Copy-Item "$PSScriptRoot\lib\NativeProgressBar.dll" "$destDll" -Force -Passthru

        if($LoadModules){

            Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
            Write-Host "Loading DLL content `"$NewDll`" " -f Yellow
            $assembly = [System.Reflection.Assembly]::LoadFile($NewDll)
            $assLoc = $assembly.Location
            Write-Host "`n`n"
            Write-Host "================================================================" -f DarkYellow
            Write-Host "                           Import                               " -f DarkRed
            Write-Host "================================================================" -f DarkYellow
            Write-Host "NewDll   $NewDll"
            Write-Host "Assembly $assLoc"

            $NowTime = Get-Date 
            $NowTimeSeconds = ConvertTo-CTime($NowTime)
            Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
            Write-Host "import-module -Assembly `"$assembly`"" -f yellow
            $NewModule = import-module -Assembly $assembly -DisableNameChecking -Force -Scope Global -PassThru -ErrorAction Ignore
            if($NewModule -eq $Null) { throw "Error on module import!" }
            Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
            Write-Host "Adding `"LoadTime`" property to module variable`nNowTimeSeconds = $NowTimeSeconds" -f Gray
            Add-Member -InputObject $NewModule -MemberType NoteProperty -Name "LoadTime" -Value "$NowTimeSeconds"
            Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
            Write-Host "Adding `"AssemblyLocation`" property to module variable.`n$assLoc" -f Gray
            Add-Member -InputObject $NewModule -MemberType NoteProperty -Name "AssemblyLocation" -Value "$assLoc"

            Write-Host "`n`t[INFO]`t" -f Yellow -NoNewLine
            Write-Host "Creating a new PsObject from the Module PsObject instance we just received." -f Gray
            Write-Host "`t[INFO]`t" -f Yellow -NoNewLine
            Write-Host "This new PsObject properties have been validated for exactitude of values, " -f Gray
            Write-Host "`t[INFO]`t" -f Yellow -NoNewLine
            Write-Host "strings whitespaces, etc, so value comparisons and processing will be solid`n" -f Gray
            $NewModuleObject = New-ModuleObject $NewModule

            if($Verbose){
                Write-ModuleObjectDump $NewModuleObject
            }
            
            [void]$NativeProgressModules.Add($NewModuleObject)
            Set-Variable -Name "NativeProgressModules" -Value $NativeProgressModules -Option AllScope -Force -Visibility Public -Scope Global -ErrorAction Ignore

            # Initialized Flag
            Set-Variable -Name "NativeProgressModuleInitialized" -Value 1 -Option AllScope -Force -Visibility Public -Scope Global -ErrorAction Ignore
        }
    }catch [Exception]{
        Write-Error "$_"
    }
    return $null
}


function Update-VariablesFromLoadedModules{

  
    [CmdletBinding(SupportsShouldProcess)]
    param(    
        [Parameter(Mandatory=$false, HelpMessage="Reload")]
        [Switch]$Reload
    ) 
  
    try{

        $NativeProgressModulesCount = 0
        [System.Collections.ArrayList]$NativeProgressModules = Get-Variable -Name "NativeProgressModules" -ValueOnly -Scope Global -ErrorAction Ignore
        if($NativeProgressModules -ne $Null){
            $NativeProgressModulesCount = $NativeProgressModules.Count 
        }

        Write-Host "==============================" -f DarkCyan
        Write-Host "List Previously Loaded Modules" -f DarkGray
        $PreviouslyLoadedModules =  Get-Module -Name "*NativeProgress*" 
        $PreviouslyLoadedModulesCount = $PreviouslyLoadedModules.Count


        Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
        Write-Host "Loaded NativeProgress Modules : $PreviouslyLoadedModulesCount" -f DarkYellow
  
        if($PreviouslyLoadedModulesCount -gt 0){
            Write-Host "`nLoaded NativeProgress Modules" -f DarkCyan
            Write-Host "=============================" -f DarkGray
            Write-Host "Getting LastWriteTime for Modules..." -f DarkGray
            ForEach($npmod in $PreviouslyLoadedModules){
                $ModuleName = $npmod.Name 
                $ModulePath = $npmod.Path
                $LastWriteTime = (gi $ModulePath).LastWriteTime
                Add-Member -InputObject $npmod -MemberType NoteProperty -Name "LastWriteTime" -Value "$LastWriteTime"
                Write-Host "`t- $ModuleName => $LastWriteTime" -f DarkGray
            }
            Write-Host "Sorting Previously Loaded Modules based on LastWriteTime" -f DarkGray
            $PreviouslyLoadedModules = $PreviouslyLoadedModules | sort -Property "LastWriteTime" -Descending
            ForEach($npmod in $PreviouslyLoadedModules){
                $ModuleName = $npmod.Name 
                $ModulePath = $npmod.Path
                $ModuleLastWriteTime = $npmod.LastWriteTime
                $NowTimeSeconds = ConvertTo-CTime($ModuleLastWriteTime)
             
                $NowTime = Get-Date 
                $NowTimeSeconds = ConvertTo-CTime($NowTime)
                $AssemblyLocation = $npmod.AssemblyLocation 
                if([string]::IsNullOrEmpty($AssemblyLocation)){
                    $AssemblyLocation = $ModulePath
                    Add-Member -InputObject $NewModule -MemberType NoteProperty -Name "AssemblyLocation" -Value "$AssemblyLocation" -ErrorAction Ignore
                    $npmod.AssemblyLocation = "$AssemblyLocation"
                    Write-Host "Updating `"AssemblyLocation`" for Module $ModuleName.`n`t  `"$AssemblyLocation`"" -f Yellow
                }

                $LoadTime = $npmod.LoadTime
                if([string]::IsNullOrEmpty($LoadTime)){
                    $NowTimeSeconds = ConvertTo-CTime($ModuleLastWriteTime)
                   
                    Add-Member -InputObject $NewModule -MemberType NoteProperty -Name "LoadTime" -Value "$NowTimeSeconds" -ErrorAction Ignore
                    $npmod.LoadTime = "$NowTimeSeconds"
                    Write-Host "Updating `"LoadTime`" for Module $ModuleName. NowTimeSeconds $NowTimeSeconds" -f Yellow
                }
                $Basename = (Get-Item "$AssemblyLocation").Basename
         
                $LoadTime = $npmod.LoadTime 
                $SecondsSinceLoaded = $NowTimeSeconds - $LoadTime
                
                [string]$LogStr = "`t- Module {0} Created on {1}, Loaded since {2} minutes.`n`t  {3}" -f $Basename, $LastWriteTime, ([math]::Round($SecondsSinceLoaded/60)), $AssemblyLocation 
                Write-Host $LogStr -f Yellow

                if($NativeProgressModulesCount -gt 0){
                    ForEach($tmpmodvar in $NativeProgressModules){
                        $TmpModuleName = $tmpmodvar.Name 
                        $TmpModulePath = $tmpmodvar.Path

                        $module_object = Get-NativeProgressModulesVariable -ModulePath "$TmpModulePath"
                        if($module_object -eq $Null){
                            $module_object = New-ModuleObject $npmod
                            [void]$NativeProgressModules.Add($module_object)
                            Set-Variable -Name "NativeProgressModules" -Value $NativeProgressModules -Option AllScope -Force -Visibility Public -Scope Global -ErrorAction Ignore
                            Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
                            Write-Host "Adding one object in variable `"NativeProgressModules`"" -f DarkCyan
                        }else{
                            $module_object = New-ModuleObject $npmod
                            $index = Get-NativeProgressModulesVariableIndex -ModulePath $TmpModulePath
                            Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
                            Write-Host "Searching for entry in vlariable. Index `"index`"" -f DarkCyan

                            if($NativeProgressModules[$index] -eq $Null){
                                $NativeProgressModules[$index] = New-ModuleObject $npmod
                            }else{
                                $NowTime = Get-Date 
                                $NowTimeSeconds = ConvertTo-CTime($NowTime)
                                $ModVarLastWriteTime = (gi $TmpModulePath).LastWriteTime
                                $TmpModuleAssemblyLocation = $NativeProgressModules[$index].AssemblyLocation 
                                if([string]::IsNullOrEmpty($TmpModuleAssemblyLocation)){
                                    $TmpModuleAssemblyLocation = $TmpModulePath
                                    Add-Member -InputObject $NativeProgressModules[$index] -MemberType NoteProperty -Name "AssemblyLocation" -Value "$TmpModulePath" -ErrorAction Ignore
                                    $NativeProgressModules[$index].AssemblyLocation = "$AssemblyLocation"
                                    Write-Host "Updating `"AssemblyLocation`" for Module $TmpModuleName.`n`t  `"$TmpModuleAssemblyLocation`"" -f Yellow
                                }

                                $TmpModVarLoadTime = $NativeProgressModules[$index].LoadTime
                                if([string]::IsNullOrEmpty($TmpModVarLoadTime)){
                                    $ModVarLastWriteTimeSeconds = ConvertTo-CTime($ModVarLastWriteTime)
                                   
                                    Add-Member -InputObject $NativeProgressModules[$index] -MemberType NoteProperty -Name "LoadTime" -Value "$ModVarLastWriteTimeSeconds" -ErrorAction Ignore
                                    $NativeProgressModules[$index].LoadTime = "$ModVarLastWriteTimeSeconds"
                                    Write-Host "Updating `"LoadTime`" for Module $TmpModuleName. NowTimeSeconds $ModVarLastWriteTimeSeconds" -f Yellow
                                }
                            }
                            Set-Variable -Name "NativeProgressModules" -Value $NativeProgressModules -Option AllScope -Force -Visibility Public -Scope Global -ErrorAction Ignore
                            Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
                            Write-Host "Updating object in variable `"NativeProgressModules`"" -f DarkCyan
                        }
                    }
                }else{
                    ForEach($npmod in $PreviouslyLoadedModules){
                        $module_object = New-ModuleObject $npmod
                        [void]$NativeProgressModules.Add($module_object)
                        Set-Variable -Name "NativeProgressModules" -Value $NativeProgressModules -Option AllScope -Force -Visibility Public -Scope Global -ErrorAction Ignore
                        Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
                        Write-Host "Adding one object in variable `"NativeProgressModules`"" -f DarkCyan
                    }
                }
                
            }
        }


    }catch [Exception]{
        Write-Error "$_"
    }
    return $null
}


function Get-NativeProgressModulesVariable{

    [CmdletBinding(SupportsShouldProcess)]
    param(    
        [Parameter(Mandatory=$true)]
        [string]$ModulePath
    ) 
  
    try{

        $NativeProgressModulesCount = 0
        [System.Collections.ArrayList]$NativeProgressModules = Get-Variable -Name "NativeProgressModules" -ValueOnly -Scope Global -ErrorAction Ignore
        if($NativeProgressModules -ne $Null){
            $NativeProgressModulesCount = $NativeProgressModules.Count 
        }        
        if($NativeProgressModulesCount -gt 0){
            ForEach($tmpmodvar in $NativeProgressModules){
                $TmpModuleName = $tmpmodvar.Name 
                $TmpModulePath = $tmpmodvar.Path
                if($TmpModulePath -eq $ModulePath){
                    return $tmpmodvar
                }
            }
        }
        return $Null

    }catch [Exception]{
        Write-Error "$_"
    }
    return $null
}


function Get-NativeProgressModulesVariableIndex{

    [CmdletBinding(SupportsShouldProcess)]
    param(    
        [Parameter(Mandatory=$true)]
        [string]$ModulePath
    ) 
  
    try{

        $NativeProgressModulesCount = 0
        [System.Collections.ArrayList]$NativeProgressModules = Get-Variable -Name "NativeProgressModules" -ValueOnly -Scope Global -ErrorAction Ignore
        if($NativeProgressModules -ne $Null){
            $NativeProgressModulesCount = $NativeProgressModules.Count 
        }        
        if($NativeProgressModulesCount -gt 0){
            For($i = 0 ; $i -le $NativeProgressModulesCount ; $i++){
                $tmpmodvar = $NativeProgressModules[$i]
                $TmpModuleName = $tmpmodvar.Name 
                $TmpModulePath = $tmpmodvar.Path
                if($TmpModulePath -eq $ModulePath){
                    return $i
                }
            }
        }
        return $Null

    }catch [Exception]{
        Write-Error "$_"
    }
    return $null
}

function Initialize-NativeProgressModule{

    [CmdletBinding(SupportsShouldProcess)]
    param(    
        [Parameter(Mandatory=$false, HelpMessage="NoLoad")]
        [Switch]$LoadModules
    ) 
  
    try{
        Write-Host "================================================================" -f DarkYellow
        Write-Host "              Initialize-NativeProgressModule                   " -f DarkRed
        Write-Host "================================================================" -f DarkYellow

        Write-NativeProgressModuleStates

        Remove-NativeProgressModules

        New-NativeProgressAssembly -LoadModules:$LoadModules
 

        Write-NativeProgressModuleStates


    }catch [Exception]{
        Write-Error "$_"
    }
    return $null
}

function Test-IsNativeProgressModuleLoaded{

    [CmdletBinding(SupportsShouldProcess)]
    param() 
  
    try{
        $Loaded = Test-NativeProgressModuleDependencies
        $Loaded
    }catch [Exception]{
        Write-Error "$_"
    }
    return $null
}

function Invoke-ReloadNativeProgressModule{

    [CmdletBinding(SupportsShouldProcess)]
    param() 
  
    try{
        Write-Host "================================================================" -f DarkYellow
        Write-Host "                Reload-NativeProgressModule                     " -f DarkRed
        Write-Host "================================================================" -f DarkYellow

        Remove-NativeProgressModules

        $Unloaded = Test-NativeProgressModuleUnloaded
        if($Unloaded -eq $True){
            Write-Host "[  OK  ] " -n -f DarkGreen
            Write-Host " UNLOAD COMPLETE" -f DarkCyan
            New-NativeProgressAssembly -LoadModules
        }else{
            Write-Host "[ERROR] " -n -f DarkRed
            Write-Host " NOT FULLY UNLOADED" -f DarkYellow
            $CommandLineToRun = Get-Process -Id $PID  |  Select -ExpandProperty CommandLine
            Start-Process "$CommandLineToRun"
            Get-Process -Id $PID  | Stop-Process
            return
        }

    }catch [Exception]{
        Write-Error "$_"
    }
    return $null
}


function Test-NativeProgressModuleDependencies{

    [CmdletBinding(SupportsShouldProcess)]
    param() 
      
    Write-Host "================================================================" -f DarkYellow
    Write-Host "                      Checking Dependencies                     " -f DarkRed
    Write-Host "================================================================" -f DarkYellow

    $FunctionDependencies = @( 'Register-NativeProgressBar', 'Unregister-NativeProgressBar', 'Write-NativeProgressBar' )
    $Script:DependenciesReady = $False
    try{
        Write-Host "[TEST] " -f Blue -NoNewLine
        Write-Host "CHECKING FUNCTION DEPENDENCIES..."
        $FunctionDependencies.ForEach({
            $Function=$_
            $FunctionPtr = Get-Command "$Function" -ErrorAction Ignore
            if($FunctionPtr -eq $null){
                throw "ERROR: MISSING $Function function. Please import the required dependencies"
            }else{
                Write-Host "`t[OK]`t" -f DarkGreen -NoNewLine
                Write-Host "$Function"
            }
        })
        Write-Host "================================================================" -f DarkYellow
        Write-Host "[SUCCESS]" -f DarkGreen -NoNewLine
        Write-Host " All Functions Dependencies are validated"
        Write-Host "================================================================" -f DarkYellow
        $Script:DependenciesReady = $True
        return  $Script:DependenciesReady
    }catch [Exception]{
        Write-Error $_ 
         $Script:DependenciesReady = $False
    }
    return  $Script:DependenciesReady
}


if($ReloadModule){
    try{

        Invoke-ReloadNativeProgressModule

        Write-NativeProgressModuleStates


    }catch [Exception]{
        Write-Error "$_"
    }

}elseif($LoadOnce){
    $Loaded = Test-NativeProgressModuleDependencies
    if($Loaded -eq $False){
        New-NativeProgressAssembly -LoadModules
    }
    
}