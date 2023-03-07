

$Script:PathList = @(
        '\\host1\c$\Users\user1\AppData\Roaming\Zoom\bin\Zoom.exe',
        '\\host2\c$\Users\user2\AppData\Roaming\Zoom\bin\Zoom.exe',
        '\\host3\c$\Users\user3\AppData\Roaming\Zoom\bin\Zoom.exe',
        '\\host4\c$\Users\user4\AppData\Roaming\Zoom\bin\other.exe',
        '\\host5\c$\Program Files\Microsoft Office\root\Office16\EXCEL.EXE',
        'non-matching-junk'
    )


function Test-RegExPattern{
    Write-Host "================================================================" -f DarkRed
    Write-Host "                          TEST REGEX                            " -f DarkYellow
    Write-Host "================================================================" -f DarkRed


    [regex]$regexpattern = [regex]::new('([\\]+)(?<HostName>[\w]+)([\\]+)(?<Drive>[c$]+)([\\Users]+)(?<Username>[\w]+)([\\]+)(?<FilePath>[AppData\\Roaming\\Zoom\\bin\\Zoom.exe]+)')

    foreach ( $path in $Script:PathList ) {
        $MatchDetected = $path -match $regexpattern
        if($MatchDetected -eq $True){
            $HostName = $Matches.HostName
            $Drive    = $Matches.Drive
            $Username = $Matches.Username
            $FilePath = $Matches.FilePath
            Write-Host "Match detected for `"$data`" Groups:"
            Write-Host "HostName " -n -f Gray ; Write-Host "$HostName" -f DarkCyan
            Write-Host "Drive    " -n -f Gray ; Write-Host "$Drive"    -f DarkCyan
            Write-Host "Username " -n -f Gray ; Write-Host "$Username" -f DarkCyan
            Write-Host "FilePath " -n -f Gray ; Write-Host "$FilePath" -f DarkGray

        } 
    }
}




function Get-CsvOutput{

    # create a regex pattern to parse the path with hostname and the username...
    [regex]$regexpattern = [regex]::new('([\\]+)(?<HostName>[\w]+)([\\]+)(?<Drive>[c$]+)([\\Users]+)(?<Username>[\w]+)([\\]+)(?<FilePath>[AppData\\Roaming\\Zoom\\bin\\Zoom.exe]+)')
 
    $StrHeaderOut = "{0}, {1}`n" -f 'HostName', 'Username'
    $CsvData += $StrHeaderOut
    
    foreach ( $i in $PathList ) {                       # loop in the path list to find matches
        $MatchDetected = $i -match $regexpattern        # use the regex variable to find matches
        if($MatchDetected -eq $True){
            $HostName = $Matches.HostName               # if match found, retrieve the hostname
            $Username = $Matches.Username               # if match found, retrieve the username
            $StrDataOut = "{0}, {1}`n" -f $HostName, $Username      # create a simple string
            $CsvData += $StrDataOut                     # add the string to the total csv data
        }
    }
    $CsvData
}


Get-CsvOutput