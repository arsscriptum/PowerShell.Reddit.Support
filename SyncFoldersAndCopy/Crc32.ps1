
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>




function Get-CRC32 {
    <#
        .SYNOPSIS
            Calculate CRC.
        .DESCRIPTION
            This function calculates the CRC of the input data using the CRC32 algorithm.
        .EXAMPLE
            Get-CRC32 $data
        .EXAMPLE
            $data | Get-CRC32
        .INPUTS
            byte[]
        .OUTPUTS
            uint32
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Array of Bytes to use for CRC calculation
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [byte[]]$InputObject
    )

    Begin {

        function New-CrcTable {
            [uint32]$c = $null
            $crcTable = New-Object 'System.Uint32[]' 256

            for ($n = 0; $n -lt 256; $n++) {
                $c = [uint32]$n
                for ($k = 0; $k -lt 8; $k++) {
                    if ($c -band 1) {
                        $c = (0xEDB88320 -bxor ($c -shr 1))
                    }
                    else {
                        $c = ($c -shr 1)
                    }
                }
                $crcTable[$n] = $c
            }

            Write-Output $crcTable
        }

        function Update-Crc ([uint32]$crc, [byte[]]$buffer, [int]$length) {
            [uint32]$c = $crc

            if (-not($script:crcTable)) {
                $script:crcTable = New-CrcTable
            }

            for ($n = 0; $n -lt $length; $n++) {
                $c = ($script:crcTable[($c -bxor $buffer[$n]) -band 0xFF]) -bxor ($c -shr 8)
            }

            Write-output $c
        }

        $dataArray = @()
    }

    Process {
        foreach ($item  in $InputObject) {
            $dataArray += $item
        }
    }

    End {
        $inputLength = $dataArray.Length
        Write-Output ((Update-Crc –crc 0xffffffffL –buffer $dataArray –length $inputLength) -bxor 0xffffffffL)
    }
}



function Get-FileCRC32 {
    <#
        .SYNOPSIS
            Calculate CRC of a file.
        .DESCRIPTION
            This function calculates the CRC of the input file using the CRC32 algorithm.
        .EXAMPLE
            Get-FileCRC32 $path
        .INPUTS
            string
        .OUTPUTS
            uint32
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Array of Bytes to use for CRC calculation
        [Parameter(Mandatory=$true, Position = 0)]  
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The Destination Path argument must be a file. Directory paths are not allowed."
            }
            return $true 
        })]
        [string]$Path
    )
    begin{
        # Portable Get-Content to bytes
        if($($PSVersionTable.PSEdition) -eq 'Core'){
            [byte[]] $file_bytes = Get-Content -Path "$Path" -AsByteStream
        }else{
            [byte[]] $file_bytes = Get-Content -Path "$Path" -Encoding Byte
        }
    }   
    process{
      try{
        $crc = Get-CRC32 $file_bytes
        $crc
      }catch{
        write-error "$_"
      } 
    }
}



function Convert-BytesToHumanReadable{
    [CmdletBinding(SupportsShouldProcess)]
    param (
        # Array of Bytes to use for CRC calculation
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [uint64]$TotalBytes
    )   
    $TotalKb =  ($TotalBytes / 1KB)
    $TotalMb =  ($TotalBytes / 1MB)
    $TotalGb =  ($TotalBytes / 1GB)
    [string]$TotalSizeInBytesStr = "{0:n2} Bytes" -f $TotalBytes
    [string]$TotalFolderSizeInKB = "{0:n2} KB" -f $TotalKb 
    [string]$TotalFolderSizeInMB = "{0:n2} MB" -f $TotalMb
    [string]$TotalFolderSizeInGB = "{0:n2} GB" -f $TotalGb
    [string]$res_str = ""
    if($TotalBytes -gt 1GB){
        $res_str =  $TotalFolderSizeInGB
    }elseif($TotalBytes -gt 1MB){
        $res_str =  $TotalFolderSizeInMB
    }elseif($TotalBytes -gt 1KB){
        $res_str =  $TotalFolderSizeInKB
    }else{
        $res_str =  $TotalSizeInBytesStr
    }
    return $res_str
}


function Test-CRC32{
    [CmdletBinding(SupportsShouldProcess)]
    param()

    [byte[]]$testCrc = 44,6,119,207
    [byte[]]$testData = 73,72,68,82,0,0,0,32,0,0,0,32,1,0,0,0,1

    # should be the same
    [array]::Reverse($testCrc)
    [System.BitConverter]::ToUInt32($testCrc,0)
    Get-CRC32 $testData

    # big file
    $f = "E:\Videos\___ZZZ_LAST_MOVIES\The Sum Of All Fears (2002)1080p.BluRay\The Sum Of All Fears (2002)1080p.BluRay.mp4"
    $file_length = (Get-Item $f).Length
    $size_str = Convert-BytesToHumanReadable $file_length
    Write-Host "Hashing...Please wait." -f DArkYellow
    $time_spent = Measure-Command { $hash = (Get-FileHash -Path "$f").Hash } 
    $log_results =  "Test MD5 Hash, file length {0} ({1} bytes): {2:N2} seconds" -f $size_str, $file_length, $time_spent.TotalSeconds
    Write-Host "$log_results" -f DarkYellow
    $time_spent = Measure-Command { $hash = Get-FileCRC32 -Path "$f" } 
    $log_results =  "Test File CRC32, file length {0} ({1} bytes): {2:N2} seconds" -f $size_str, $file_length, $time_spent.TotalSeconds
    Write-Host "$log_results" -f DarkYellow
}



Test-CRC32