
[CmdletBinding(SupportsShouldProcess)]
param()


function Copy-CustomLocation{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$True, Position=0, HelpMessage="Source file path")]
        [Alias('p')]
        [string[]]$Path,
        [Parameter(Mandatory=$True, Position=1, HelpMessage="Destination directory")]
        [Alias('dst', 'd')]
        [string]$Destination,
        [Parameter(Mandatory=$false, HelpMessage="No Errors please")]
        [switch] $SilentErrors    
    ) 
    try{
        # An ArrayList containing all the errors that can occur whilst copying files (access errors, write error, etc...)
        [System.Collections.ArrayList]$AllCopyErrors = [System.Collections.ArrayList]::new()

        ForEach($file in $Path){
            try{
                $fileinfo = Get-Item $file
                $parent_directory_path = $fileinfo.DirectoryName
                $file_full_path = $fileinfo.FullName
                $file_name = $fileinfo.Name
                $path_leaf = Split-Path "$parent_directory_path" -Leaf

                # the root directory, where all the new folders are created and files are copied
                $destination_directory = Join-Path $Destination $path_leaf

                # the full file path of the copied file (including the new parent directory)
                $destination_fullpath = Join-Path $destination_directory $file_name

                $logstring = "from {0}`n  to {1}`nleaf {2}`nfull {3}`n" -f $file_full_path, $Destination, $path_leaf, $destination_fullpath 
                Write-Verbose "$logstring"

                # Create the destination directory for that file
                $Null = New-Item -Path "$destination_directory" -ItemType Directory -Force -ErrorAction Ignore -ErrorAction "Silent" -ErrorVariable CreateDirectoryErrors
                $Null = Copy-Item -Path "$file_full_path" -Destination "$destination_fullpath" -Force -ErrorAction "Silent" -ErrorVariable CopyItemErrors

                if($($CreateDirectoryErrors.Count) -gt 0){
                    $CreateDirectoryErrors | % {
                        Write-Verbose "Adding CreateDirectory Error: $_"
                        [void]$AllCopyErrors.Add("$($_)")
                    }  
                }
                if($($CopyItemErrors.Count) -gt 0){
                    $CopyItemErrors | % {
                        Write-Verbose "Adding CopyItem Error: $_"
                        [void]$AllCopyErrors.Add("$($_)")
                    }  
                }
            }catch{ 
                [void]$AllCopyErrors.Add("$($_)")
            }
        }
        if($SilentErrors -eq $False){
            $AllCopyErrorsCounts = $AllCopyErrors.Count
            if($AllCopyErrorsCounts -gt 0){
                Write-Warning "Total Copy Errors: $AllCopyErrorsCounts"
                $AllCopyErrors | % {
                    Write-Warning "Copy Error: $($_)"
                }               
            }
        }

    }catch{ 
        Write-Error "$_"
    }
}

#$filelist = Get-ChildItem -Path "F:\Temp\COPY_SOURCE" -File -Filter "*.ps1" -Recurse | Select -First 5 | Select -ExpandProperty FullName
$filelist = Get-Content -Path "F:\Temp\COPY_SOURCE_LIST.txt"
Copy-CustomLocation -Path $filelist -Destination "F:\Temp\COPY_DEST"