<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>



<# 
 - pattern:
   - 4 spaces
   - date like 8/20/2023        
   - 1 space
   - hour like 6:19:42
   - 1 space
   - AM ro PM
   - 7 spaces
   - computer name


    |      **Group**      |                       **Pattern**                        |
    |:-------------------:|:--------------------------------------------------------:|
    |     4 spaces        |   ^(?<FourSpaces>( ){4})                                 |
    |     8/20/2023       |   (?<Date>[0-3]?[0-9].[0-3]?[0-9].(?:[0-9]{2})?[0-9]{2}) |
    |       1 space       |   (?<OneSpace1>( ){1})                                   |
    |       6:19:42       |   (?<Hour>[\d+:\d+:\d+]+)                                |
    |       1 space       |   (?<OneSpace2>( ){1})                                   |
    |      AM or PM       |   (?<PmAm>[PM|AM]+)                                      |
    |       7 spaces      |   (?<SevenSpaces>( ){7})                                 |
    |    computer name    |   (?<Computer>[\w\\]+)                                   |



(?<Date>[0-3]?[0-9].[0-3]?[0-9].(?:[0-9]{2})?[0-9]{2})(?<OneSpaces>( ){1})(?<Hour>[\d+:\d+:\d+]+)(?<OneSpaces>( ){1})(?<PmAm>[PM|AM]+)(?<SevenSpaces>( ){7})


(?<Date>[0-3]?[0-9].[0-3]?[0-9].(?:[0-9]{2})?[0-9]{2})(?<OneSpaces>( ){1})(?<Hour>[\d+:\d+:\d+]+)(?<OneSpaces>( ){1})(?<PmAm>[PM|AM]+)(?<SevenSpaces>( ){7})(?<Computer>[\w\\]+)


(?<Date>[0-3]?[0-9].[0-3]?[0-9].(?:[0-9]{2})?[0-9]{2})


[RegEx]$pattern = '^(?<FourSpaces>( ){4})(?<Date>[0-3]?[0-9].[0-3]?[0-9].(?:[0-9]{2})?[0-9]{2})(?<OneSpace1>( ){1})(?<Hour>[\d+:\d+:\d+]+)(?<OneSpace2>( ){1})(?<PmAm>[PM|AM]+)(?<SevenSpaces>( ){7})(?<Computer>[\w\\]+)'

#>




function Get-LoggedOnUsers2 { 
    [CmdletBinding(SupportsShouldProcess)]
    Param()
    
    begin{

        [string]$PsLoggedon64Exe = Search-PsLoggedOnApp
        if([string]::IsNullOrEmpty($PsLoggedon64Exe)){
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
        [System.Collections.ArrayList]$Users = [System.Collections.ArrayList]::new()
        [string[]]$Output = &"$PsLoggedon64Exe" "-nobanner"
        [uint32]$OutputCount = $Output.Count
        if($OutputCount -le 2){ throw "invalid data" }
        [RegEx]$pattern = '^(?<All>(?<Date>[0-3]?[0-9].[0-3]?[0-9].(?:[0-9]{2})?[0-9]{2})(?<OneSpace1>( ){1})(?<Hour>[\d+:\d+:\d+]+)(?<OneSpace2>( ){1})(?<PmAm>[PM|AM]+))'
        ForEach($line in $Output){
            if($line -match '^(?<FourSpaces>( ){4})'){
                $trimmed_line = $line.TrimStart()
                if($trimmed_line -match $pattern){
                    $MatchesAll = $Matches.All
                    [DateTime]$LoginTime = $MatchesAll
                    [string]$ComputerName = $trimmed_line.Replace($MatchesAll,"").TrimStart().TrimEnd()
                    [PsCustomObject]$o = [PsCustomObject]@{
                        LoginTime = $LoginTime
                        ComputerName = $ComputerName
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



function Get-LoggedOnUsers2 { 
    [CmdletBinding(SupportsShouldProcess)]
    Param()
    begin{

        [string]$PsLoggedon64Exe = Search-PsLoggedOnApp
        if([string]::IsNullOrEmpty($PsLoggedon64Exe)){
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
        $i = 0
        [System.Collections.ArrayList]$Users = [System.Collections.ArrayList]::new()
        [string[]]$Output = &"$PsLoggedon64Exe" "-nobanner"
        [uint32]$OutputCount = $Output.Count
        if($OutputCount -le 2){ throw "invalid data" }
        ForEach($line in $Output){
            Write-Verbose "PARSING LINE NUM $i"
            if($line -match '^(?<FourSpaces>( ){4})'){
                Write-Verbose "MATCH! line `"$line`""
                $trimmed_line = $line.TrimStart()
                Write-Verbose "trimmed_line `"$trimmed_line`""
                [String]$DateStr = $trimmed_line.Substring(0,27)
                Write-Verbose "DateStr `"$DateStr`""
                #[DateTime]$LoginTime = $DateStr -as [DateTime]
                [string]$ComputerName = $trimmed_line.Substring(27).Trim()
                Write-Verbose "ComputerName `"$ComputerName`""
                [PsCustomObject]$o = [PsCustomObject]@{
                    LoginTime = $DateStr
                    ComputerName = $ComputerName
                }
                [void]$Users.Add($o)
            }
            $i++
        }
        $Users
       
      }catch{
        throw $_
      }
    }
}
