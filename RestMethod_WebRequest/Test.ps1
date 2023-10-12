<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


function Get-MyIpTest {  
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$true, Position = 0)]
        [ValidateSet('RestMethod','WebRequest')]
        [String]$Cmdlet,
        [Parameter(Mandatory=$false)]
        [ValidateSet('json','csv','jsonp','text')]
        [String]$Format='json',
        [Parameter(Mandatory=$false)]
        [switch]$GetHtml
    )
    
    try{
        $FormatArgument = "format={0}" -f $Format
        $BaseUrl = "https://api.ipify.org"

        $FullUrl = "{0}?{1}" -f $BaseUrl, $FormatArgument

        if($GetHtml -eq $True){
            $FullUrl = "https://arsscriptum.github.io/welcome.html"
        }
        if($Cmdlet -eq 'RestMethod'){
            $Ret = Invoke-RestMethod -Uri "$FullUrl" -UserAgent "PowerShell" -Method Get
        }else{
            $Ret = Invoke-WebRequest -Uri "$FullUrl" -UserAgent "PowerShell" -Method Get
        }   
        $Ret
        
    }catch{
        Write-Error "[ERROR OCCURED] $_"
    }
}



<#

###########################################
# TEST 1: Invoke-RestMethod - Text return
# Here you get the text, directly, the return object is already parsed.

PS> Get-MyIpTest -Cmdlet RestMethod -Format text
PS> 
PS> 10.1.1.1

###########################################
# TEST 2: Invoke-RestMethod - JSON return
# Here you get a PSOBJECT, directly, the JSON return object is already parsed in a PSOBJECT

PS> Get-MyIpTest -Cmdlet RestMethod -Format text
PS> 
PS> ip
PS> --
PS> 10.1.1.1


###########################################
# TEST 3: Invoke-WebRequest - Text return
# Here we get a return PSObject containing all the HTTP Request return information, the content property has our data

PS> Get-MyIpTest -Cmdlet WebRequest -Format text
PS> 
PS> StatusCode        : 200
PS> StatusDescription : OK
PS> Content           : {"ip":"10.1.1.1"}
PS> RawContent        : HTTP/1.1 200 OK
PS>                     Server: nginx/1.25.1
PS>                     Date: Thu, 12 Oct 2023 16:01:00 GMT
PS>                     Connection: keep-alive
PS>                     Vary: Origin
PS>                     Content-Type: application/json
PS>                     Content-Length: 23
PS> 
PS>                     10.1.1.1
PS> Headers           : {[Server, System.String[]], [Date, System.String[]], [Connection, System.String[]], [Vary,
PS>                     System.String[]]…}
PS> Images            : {}
PS> InputFields       : {}
PS> Links             : {}
PS> RawContentLength  : 23
PS> RelationLink      : {}




###########################################
# TEST 4: Invoke-WebRequest - Json return
PS> Get-MyIpTest -Cmdlet WebRequest -Format json
# Here we get a return PSObject containing all the HTTP Request return information, the content property has our data

PS> 
PS> StatusCode        : 200
PS> StatusDescription : OK
PS> Content           : {"ip":"10.1.1.1"}
PS> RawContent        : HTTP/1.1 200 OK
PS>                     Server: nginx/1.25.1
PS>                     Date: Thu, 12 Oct 2023 16:02:00 GMT
PS>                     Connection: keep-alive
PS>                     Vary: Origin
PS>                     Content-Type: application/json
PS>                     Content-Length: 23
PS> 
PS>                     {"ip":"10.1.1.1"}
PS> Headers           : {[Server, System.String[]], [Date, System.String[]], [Connection, System.String[]], [Vary,
PS>                     System.String[]]…}
PS> Images            : {}
PS> InputFields       : {}
PS> Links             : {}
PS> RawContentLength  : 23
PS> RelationLink      : {}


PS> $Data = Get-MyIpTest -Cmdlet WebRequest -Format json
PS> if($($Data.StatusCode) -ne 200) { throw "Error in request, Returned $($Data.StatusCode)" }
PS> $JsonData = $Data.Content | ConvertFrom-Json
PS> Write-Host "SatusCode returned was $($Data.StatusCode)" -f DarkMagenta
PS> Write-Host "my ip is $($JsonData.ip)" -f DarkCyan

PS> SatusCode returned was 
PS> my ip is 10.17.18.33


## Here's where you'll see an issue


Look at when you do a request and get HTML (which cannot be parsed by Inboke-RestMethod)

```bash
 PS> Get-MyIpTest RestMethod -Format csv -GetHtml

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta content="width=device-width, initial-scale=1.0" name="viewport">
  <title>Guillaume Plante</ti
```


Look at when you do a request and get HTML which is parsed


```bash
 PS> Get-MyIpTest WebRequest -Format csv -GetHtml

    PS> 
    PS> StatusCode        : 200
    PS> StatusDescription : OK
    PS> Content           : {"ip":"10.1.1.1"}
    PS> RawContent        : HTTP/1.1 200 OK
    PS>                     Server: nginx/1.25.1
    PS>                     Date: Thu, 12 Oct 2023 16:02:00 GMT
    PS>                     Connection: keep-alive
    PS>                     Vary: Origin
    PS>                     Content-Type: application/json
    PS>                     Content-Length: 23
    PS> 
```


#>