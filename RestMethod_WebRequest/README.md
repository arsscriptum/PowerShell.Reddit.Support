# Difference between Invoke-RestMethod and Invoke-WebRequest

The 2 are equivalent, but the difference is that ```Invoke-RestMethod``` will auto-detect the return data and will parse it for you if it is JSON. In your case, the REDDIT API, the return is JSON so it's cool. ```Invoke-RestMethod``` is perfect for quick APIs that have no special response information such as ```Headers``` or ```Status Codes```, whereas ```Invoke-WebRequest``` gives you full access to the Response object and all the details it provides.

Me I prefer using ```Invoke-WebRequest``` because it gives me more control over what I do with the return data. I very rarely use ```Invoke-RestMethod``` I use ```Invoke-WebRequest``` and parse the data with ```ConvertFrom-Json``` but that my personal preference. You do what you do, it results in the same thing if you are receiving JSON. It's my style it's all

Like here's an example of how to handle errors with ```Invoke-WebRequest```

```
  $req = Invoke-WebRequest -Uri "YourMom.com"
  if($($req.StatusCode) -ne 200) { throw "Error in request, Returned $($req.StatusCode)" }
  $JsonData = $ret.Content | ConvertFrom-Json
  Write-Host "Her size is $($JsonData.Weight)" -f Red
```

### Test Function

Let's use this function, which can get your external ip from ```https://api.ipify.org``` in format ```text``` or ```json``` and use it to test ```Invoke-WebRequest``` and ```Invoke-RestMethod```

```powershell
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

        if($SimulateError -eq $True){
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
```

### Test

```bash
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
```