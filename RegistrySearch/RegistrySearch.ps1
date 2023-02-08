
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

function Search-Registry { 
<# 
.SYNOPSIS 
Searches registry key names, value names, and value data (limited). 

.DESCRIPTION 
This function can search registry key names, value names, and value data (in a limited fashion). It outputs custom objects that contain the key and the first match type (KeyName, ValueName, or ValueData). 

.OUTPUTS
Returns a list of objects with following properties: Registry Key Path, Reason, matched String

.EXAMPLE 
# Search ANY Value Names, Value Data and Key Names matching string "svchost"
Search-Registry -Path HKLM:\SYSTEM\CurrentControlSet\Services\* -SearchRegex "svchost" 

.EXAMPLE 
Search-Registry -Path HKLM:\SOFTWARE\Microsoft -Recurse -ValueNameRegex "ValueName1|ValueName2" -ValueDataRegex "ValueData" -KeyNameRegex "KeyNameToFind1|KeyNameToFind2" 

.EXAMPLE
# HKEY_CURRENT_USER, HKEY_CLASSES_ROOT, HKEY_LOCAL_MACHINE for strings 'Wavsor' and 'Wavebrowser'
$RootRegistryPath = @("HKLM:\", "HKCU:\")
Search-Registry -Path $RootRegistryPath -SearchRegex "Wavebrowser|Wavsor"
#> 
    [CmdletBinding()] 
    param( 
        [Parameter(Mandatory=$true, Position=0, ValueFromPipelineByPropertyName=$true, HelpMessage="The Paths to search in")] 
        [Alias("p", "PsPath")] 
        [string[]] $Path, 
        [Parameter(Mandatory=$true, Position=1, ValueFromPipelineByPropertyName=$true, HelpMessage="Search string regex")] 
        [string] $SearchRegex, 
        [Parameter(Mandatory=$false, HelpMessage="Compare the -SearchRegex string parameter to the registry key name")] 
        [switch] $KeyName, 
        [Parameter(Mandatory=$false, HelpMessage="Compare the -SearchRegex string parameter to the registry property name")] 
        [switch] $PropertyName, 
        [Parameter(Mandatory=$false, HelpMessage="Compare the -SearchRegex string parameter to the registry property value")] 
        [switch] $PropertyValue, 
        [Parameter(Mandatory=$false, HelpMessage="No Errors please")]
        [switch] $SilentErrors,
        [Parameter(Mandatory=$false, HelpMessage="Depth of recursion")]
        [uint32] $Depth,
        [Parameter(Mandatory=$false, HelpMessage="Specifies whether or not all subkeys should also be searched ")]
        [switch] $Recurse
    ) 

    begin { 
        [string] $KeyNameRegex=''
        [string] $PropertyNameRegex=''
        [string] $PropertyValueRegex=''

        $NoSwitchesSpecified = -not ($PSBoundParameters.ContainsKey("KeyName") -or $PSBoundParameters.ContainsKey("PropertyName") -or $PSBoundParameters.ContainsKey("PropertyValue")) 
        Write-Verbose "NoSwitchesSpecified  -> $NoSwitchesSpecified" 

        if ($KeyName -or $NoSwitchesSpecified) { 
            $KeyNameRegex = $SearchRegex
            Write-Verbose "SearchFor  -> KeyName `"$KeyNameRegex`""  
        } 
        if ($PropertyName -or $NoSwitchesSpecified) { 
            $PropertyNameRegex = $SearchRegex
            Write-Verbose "SearchFor  -> PropertyName `"$PropertyNameRegex"
        } 
        if ($PropertyValue -or $NoSwitchesSpecified) { 
            $PropertyValueRegex = $SearchRegex
            Write-Verbose "SearchFor  -> PropertyValue `"$PropertyValueRegex`""  
        } 
         
        
    } 

    process { 
        
        [System.Collections.ArrayList]$Results = [System.Collections.ArrayList]::new()
        foreach ($CurrentPath in $Path) { 
            if($PSBoundParameters.ContainsKey('Depth') -eq $True){
                $AllObjs = Get-ChildItem $CurrentPath -Recurse:$Recurse -ev AccessErrors -ea silent -Depth $Depth
            }else{
                $AllObjs = Get-ChildItem $CurrentPath -Recurse:$Recurse -ev AccessErrors -ea silent
            }
            
            $AllObjs | ForEach-Object { 
                    $Key = $_ 

                    if ($KeyNameRegex) {  
                        Write-Verbose ("{0}: Checking KeyNamesRegex" -f $Key.Name)  

                        if ($Key.PSChildName -match $KeyNameRegex) {  
                            $Value = $Key.PSChildName
                            Write-Verbose "  -> Match found! $Value" 
                            [PSCustomObject]$o = [PSCustomObject] @{ 
                                Key = $Key 
                                Reason = "KeyName" 
                                String = $Value
                            }
                            [void]$Results.Add($o)
                        }  
                    } 

                    if ($PropertyNameRegex) {  
                        Write-Verbose ("{0}: Checking PropertyNameRegex" -f $Key.Name) 

                        if ($Key.GetValueNames() -match $PropertyNameRegex) {  
                            
                            [string[]]$Names = $Key.GetValueNames()
                            $Value = ''
                            FOrEach($name in $Names){
                                if($name -match $PropertyNameRegex) {
                                   $Value = $name 
                                }
                            }
                            Write-Verbose "  -> Match found! $Value"
                            [PSCustomObject]$o = [PSCustomObject] @{ 
                                Key = $Key 
                                Reason = "PropertyName" 
                                String = $Value
                            } 
                            [void]$Results.Add($o)
                        }  
                    } 

                    if ($PropertyValueRegex) {  
                        Write-Verbose ("{0}: Checking PropertyValueRegex" -f $Key.Name) 
                        if (($Key.GetValueNames() | % { $Key.GetValue($_) }) -match $PropertyValueRegex) {  
                       
                            [string[]]$Names = $Key.GetValueNames()
                            $Value = ''
                            FOrEach($name in $Names){
                                $TestValue = $Key.GetValue($name) 
                                if($TestValue -match $PropertyValueRegex) {
                                   $Value = $Key.GetValue($name) 
                                }
                            }
                            Write-Verbose "  -> Match found! $Value"
                            [PSCustomObject]$o = [PSCustomObject] @{ 
                                Key = $Key 
                                Reason = "PropertyValue" 
                                String = $Value
                            } 
                            [void]$Results.Add($o)
                        } 
                    } 
                } 
        } 

        if($PSBoundParameters.ContainsKey('SilentErrors') -eq $False){
            $AccessErrorsCounts = $AccessErrors.Count
            if($AccessErrorsCounts -gt 0){

                $AccessErrors | % {
                    Write-Warning "Access Error: $($_.TargetObject)"
                }
                Write-Warning "Total Access Errors: $AccessErrorsCounts"
                
            }
        }

        return $Results
    } 
} 