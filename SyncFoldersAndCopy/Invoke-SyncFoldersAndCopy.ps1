

<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>



[CmdletBinding(SupportsShouldProcess)]
param()
    

function Invoke-SyncFoldersAndCopy{
    <#
        .SYNOPSIS
            Compare folder content, Copy and sync files that are different, missing or corrupted
        .DESCRIPTION
            Compare folder content, Copy and sync files that are different, missing or corrupted
            For speed consideration, I use this algorithm:

            1. Compare sizes
            2. Compare dates ( REMOVED )
            3. Compare the hashes
        .EXAMPLE
            Invoke-SyncFoldersAndCopy $src $dst
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(                           
        [Parameter(Mandatory=$true, Position = 0)]
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Container) ){
                throw "The Source Path argument must be a Directory. Files paths are not allowed."
            }
            return $true 
        })]       
        [string]$Source,    
        [Parameter(Mandatory=$true, Position = 1)]  
        [ValidateScript({
            if(-Not ($_ | Test-Path) ){
                throw "File or folder does not exist"
            }
            if(-Not ($_ | Test-Path -PathType Container) ){
                throw "The Destination Path argument must be a Directory. Files paths are not allowed."
            }
            return $true 
        })]
        [string]$Destination,
        [Parameter(Mandatory=$false)]         
        [string]$Filter="",      
        [Parameter(Mandatory=$false)]         
        [switch]$Recurse,
        [Parameter(Mandatory=$false)]         
        [bool]$DoCopy = $False,
        [Parameter(Mandatory=$false)]         
        [bool]$DoCopyMissing = $False
    ) 

    begin{
        $ToCopy = @()
        $MissingFiles = @()
        $CorruptedFiles = @()
        $AllSrcFiles = @()
        if([string]::IsNullOrEmpty($Filter) -eq $False){
          $AllSrcFiles = gci "$Source" -File -Recurse:$Recurse | Where Fullname -match "$Filter" | Select -ExpandProperty Fullname
        }else{
          $AllSrcFiles = gci "$Source" -File -Recurse:$Recurse | Select -ExpandProperty Fullname
        }

        $AllSrcFilesCount = $AllSrcFiles.Count

        Write-Verbose "Found $AllSrcFilesCount source files"
    }
    process{
      try{
        
        if(0 -eq $AllSrcFilesCount){ throw "No files located in source folder `"$Source`"" }

        ForEach($src_file in $AllSrcFiles){
            
            $relpath = $src_file.Replace("$Source\","")
            $dst_file = "{0}\{1}" -f $Destination , $relpath 
            Write-Verbose "- fp       `"$src_file`""
            Write-Verbose "- relpath  `"$relpath`""
            Write-Verbose "- $dst_file  `"$dst_file`"" 
           
            $dstfile_exists = Test-Path -Path "$dst_file" -PathType Leaf
            if($True -eq $dstfile_exists){
                # check for size
                [uint32]$l1 = (Get-Item -Path "$src_file").Length
                Write-Verbose "FileSize1 `"$l1`" "
                [uint32]$l2 =  (Get-Item -Path "$dst_file").Length
                Write-Verbose "FileSize2 `"$l2`" "

                if("$l1" -ne "$l2"){   
                    Write-Host "Found corrupted file `"$dst_file`" " -f Red
                    $CorruptedFiles += $dst_file
                    $ToCopy += $src_file
                    
                }else{
                    Write-Verbose "Files have similar size: `"$dst_file`" "
                    # check md5 checksum

                    $h1 = (Get-FileHash -Path "$src_file" -Algorithm MD5).Hash
                    Write-Verbose "FileHash 1 `"$h1`" "
                    $h2 = (Get-FileHash -Path "$dst_file" -Algorithm MD5).Hash
                    Write-Verbose "FileHash 2 `"$h2`" "

                    if("$h1" -eq "$h2"){   
                        Write-Verbose "Files are similar: `"$dst_file`" "
                    }else{
                        Write-Host "Found corrupted file `"$dst_file`" " -f Red
                        $CorruptedFiles += $dst_file
                        $ToCopy += $src_file
                    }
                    
                }
            }else{
                Write-Host "Missing file: `"$dst_file`"$exists2" -f Yellow
                if($DoCopyMissing -eq $True){
                    $ToCopy += $src_file
                }
                $MissingFiles += $dst_file
            }
        }
        Write-Host "`n-----------------------------------------------`nReport" -f DarkYellow
        Write-Host "Found $($CorruptedFiles.Count) Corrupted Files" -f DarkYellow        
        Write-Host "Found $($MissingFiles.Count) Missing Files`n`n" -f DarkYellow   
        if($DoCopy -eq $True){
          ForEach($file in $ToCopy){
            $src_file = $file
            $relpath = $src_file.Replace("$Source\","")
            $dst_file = "{0}\{1}" -f $Destination , $relpath 
            $Null = Remove-Item -Path "$dst_file" -Force -ErrorAction Ignore | Out-Null
            Copy-Item -Path "$src_file" -Destination "$dst_file" -Force  -ErrorAction Ignore -Verbose
          }
        }else{
          Write-Host "-----------------------------------------------" -f DarkYellow
          Write-Host "DoCopy is False -> Just print the files to copy" -f DarkYellow
          # Just list the files to copy...
          ForEach($f in $ToCopy){ Write-Host " - $f" -f DarkGray }
        }
      }catch{
        write-error "$_"
      } 
    }
}


function Test-SyncFoldersAndCopy{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    cls
    $src = "$PSScriptRoot\test_files\src"
    $dst = "$PSScriptRoot\test_files\dst"
    Invoke-SyncFoldersAndCopy -Source $src -Destination $dst
    Read-Host "continue?"
    cls
    Invoke-SyncFoldersAndCopy -Source $src -Destination $dst -Recurse
    
    Read-Host "continue?"
    cls
    # To copy the missing and corrupted files, use the line below
    #Invoke-SyncFoldersAndCopy -Source $src -Destination $dst -DoCopy $True -Recurse

}


Test-SyncFoldersAndCopy