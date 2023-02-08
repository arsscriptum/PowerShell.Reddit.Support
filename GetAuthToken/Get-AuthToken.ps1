<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>


function Get-AuthenticationToken{
    [CmdletBinding(SupportsShouldProcess)]
    param(    
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="force")]
        [switch]$Force
    ) 

    try{

        # Get the registry location for our settings
        $RegPath = Get-ModuleRegistryPath
        if( $RegPath -eq "" ) { throw "not in module"; return ;}
        $RegPath = Join-Path $RegPath 'oAuth'


        # Check if we already have a access_token and if its not timed out
        $Exists = $False
        if($Force -eq $False) {
            $Exists = Test-RegistryValue -Path "$RegPath" -Name 'access_token'    
        }
        if($Exists){
            $NowTime = Get-Date 
            $NowTimeSeconds = ConvertTo-CTime($NowTime)
            $TimeExpiredSeconds = Get-RegistryValue -Path "$RegPath" -Name 'expiration_time'
        
            $Diff = $NowTimeSeconds-$TimeExpiredSeconds
            Write-Verbose "NowTimeSeconds $NowTimeSeconds, TimeExpiredSeconds $TimeExpiredSeconds, Diff $Diff"
            $Token = Get-RegistryValue -Path "$RegPath" -Name 'access_token'
            $TokenType = Get-RegistryValue -Path "$RegPath" -Name 'token_type'
            $ExpirationTimeSeconds = Get-RegistryValue -Path "$RegPath" -Name 'expiration_time'

            Write-Verbose "Get-RegistryValue Token: $Token"
            Write-Verbose "Get-RegistryValue TokenType: $TokenType"
            Write-Verbose "Get-RegistryValue ExpirationTimeSeconds: $ExpirationTimeSeconds"

            if($Diff -lt 0){
                $UpdateWhen = 1 - $Diff 
                Write-Verbose "Use existing $Token, Update in $UpdateWhen seconds"
                return $Token
            }
        }

        $AppCredz  = Get-AppCredentials (Get-AppCredentialID)

       
        if($AppCredz -eq $Null) { throw "No credential registered. Module initialized ?" ; return $Null }
        [String]$AuthBaseUrl =  Get-SpotifyUrl -Action 'auth'

        $Params = @{
            Uri             = $AuthBaseUrl
            Body            = @{
                grant_type = 'client_credentials'
            }
            UserAgent       = Get-ModuleUserAgent
            Headers         = @{
                Authorization = $AppCredz | Get-AuthorizationHeader 
            }
            Method          = 'POST'
            UseBasicParsing = $true
        }
        Write-Verbose "Invoke-WebRequest $Params"
        $Response = (Invoke-WebRequest  @Params).Content | ConvertFrom-Json
        $ErrorType = $Response.error
        if($ErrorType -ne $Null){
            throw "ERROR RETURNED $ErrorType"
            return $Null
        }

        $AccessToken = $Response.access_token
        $TokenType = $Response.token_type
        $ExpiresInSecs = $Response.expires_in
    
        Write-Verbose "Invoke-WebRequest Response: $Response"
        Write-Verbose "Invoke-WebRequest AccessToken: $AccessToken"
        Write-Verbose "Invoke-WebRequest TokenType: $TokenType"
        Write-Verbose "Invoke-WebRequest ExpiresInSecs: $ExpiresInSecs"
        [DateTime]$NowTime = Get-Date
        [DateTime]$ExpirationTime = $NowTime.AddSeconds($ExpiresInSecs)

        $NowTimeSeconds = ConvertTo-CTime($NowTime)
        $ExpirationTimeSeconds = ConvertTo-CTime($ExpirationTime)
   
       
        $Null=New-Item -Path $RegPath -ItemType Directory -Force
        $Null = Set-RegistryValue -Path "$RegPath" -Name 'access_token' -Value $AccessToken 
        $Null = Set-RegistryValue -Path "$RegPath" -Name 'token_type' -Value $TokenType
        $Null = Set-RegistryValue -Path "$RegPath" -Name 'created_on' -Value $NowTimeSeconds
        $Null = Set-RegistryValue -Path "$RegPath" -Name 'expiration_time' -Value $ExpirationTimeSeconds
      

        return $AccessToken
    }catch{
        Show-ExceptionDetails $_ -ShowStack
    }
}
