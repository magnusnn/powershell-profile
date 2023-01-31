function Get-AzureAccessToken([string] $resource){
    (az account get-access-token --resource $resource | ConvertFrom-Json)[0].accessToken | Set-Clipboard
    Write-Host "Access token added to clipboard ✅"
}