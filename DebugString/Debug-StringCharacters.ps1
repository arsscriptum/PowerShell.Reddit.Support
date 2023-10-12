<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory=$True, Position =0)]
    [string]$String
)


function Get-ColorArray { 
    #$colors = [System.ConsoleColor].GetEnumValues()
    #$colors = @('White','DarkGray','White','DarkGray','White','White','DarkGray','White','DarkGray','White','DarkGray','White','DarkGray','White','DarkGray','White','DarkGray')
    #$colors = @('DarkRed','DarkYellow','DarkRed','DarkYellow','DarkRed','DarkRed','DarkYellow','DarkRed','DarkYellow','DarkRed','DarkYellow','DarkRed','DarkYellow','DarkRed','DarkYellow','DarkRed','DarkYellow')
    $colors = @('Cyan','Yellow','Cyan','Yellow','Cyan','Cyan','Yellow','Cyan','Yellow','Cyan','Yellow','Cyan','Yellow','Cyan','Yellow','Cyan','Yellow')
    return $colors
}


function Get-WriteHostColor([int]$index) { 
    if($index -le 1){ $index = 1 }
    if($index -gt 15){ $index = $index % 15 }

    $colors = Get-ColorArray
    return $colors[$index]
}

function Debug-StringCharacters { 
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, Position = 0)]
        [string]$String
    )
    begin{
        if([string]::IsNullOrEmpty($String)){
            throw "invalid string"
        }
        [regex]$regex_non_printable = [regex]::new('[^\x20-x7F]')
        $len = $String.Length
        Write-Verbose "Found $len chars. Using `"$String`""
        Write-Host "`n$String" 
        Write-Host "`n" 
    }
    process{
      try{

        Write-Host "`n" -n
        For($i = 0 ; $i -lt $len ; $i++){
            $col = Get-WriteHostColor($i)
            if($c -match  $regex_non_printable){ 
                $non_printable_chars++
            }
            [char]$c = $String[$i]
            [int]$ival = $c
            if($ival -eq 9){ 
                if($c -match  $regex_non_printable){ $col = 'DarkRed'  }
                Write-Host "tab " -n -f ($col)
                Write-Host "| " -n -f DarkGray
            }else{
                if($c -match  $regex_non_printable){ $col = 'DarkRed'  }
                Write-Host " $c  " -n -f ($col)
                Write-Host "| " -n -f DarkGray
            }
        }
        Write-Host "`n" -n
        For($i = 0 ; $i -lt $len ; $i++){
            [char]$c = $String[$i]
            [int]$ival = $c
            $col = Get-WriteHostColor($i)
            if($c -match  $regex_non_printable){ $col = 'DarkRed'  }
            $log = "{0:d3}" -f $ival
            Write-Host "$log " -n -f ($col)
            Write-Host "| " -n -f DarkGray
        }
        Write-Host "`n`n" 
        Write-Host "Found $non_printable_chars non printable characters in string. Painted in " -f Blue -n
        Write-Host "RED" -f DarkRed 
      }catch{
        throw $_
      }
    }
}



Debug-StringCharacters $String