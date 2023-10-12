[CmdletBinding(SupportsShouldProcess)]
param()

$test=0

function Get-ChildItemFiltered{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$False)]
        [string]$Path
    ) 
    begin{
        if([string]::IsNullOrEmpty($Path)){
            $Path = "$PSScriptRoot"
        }
    }
    process{
      try{
        $custom_gcifilter = {
            $a = @('microsoft.com','google.com','videotron.com','bell.ca','military.com','panasonic.com')
            $valid=$False;$name=$_.Name;[DateTime]$dt=$_.CreationTime;[timespan]$ts = [datetime]::now - $dt;
            if(($($ts.Minutes) -gt 10) -and ($a.Contains($name))) { $valid=$True }
            $valid
        }
      
        Get-ChildItem -Path "$Path" -Recurse | Where $custom_gcifilter
    
      }catch{
        write-error "$_"
      }
    }
}



Get-ChildItemFiltered