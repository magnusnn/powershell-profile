function jwtd([String] $token) {
    Write-Host ""
    Write-Host ""
    $tokenSplit = $token.Split('.')
    if (!$token.Contains(".") -or !$token.StartsWith("eyJ") -or $tokenSplit.Length -ne 3) { 
        Write-Error "Invalid token" -ErrorAction Stop 
    }
    
    function Get-Base64encode([String] $data){
        $data = $data.Replace('-', '+').Replace('_', '/')
        switch ($data.Length % 4) {
            0 { break }
            2 { $data += '==' }
            3 { $data += '=' }
        }
        return $data
    }

    function Get-ConvertOutput([String] $data){
        return [System.Text.Encoding]::UTF8.GetString([convert]::FromBase64String($data)) | ConvertFrom-Json | ConvertTo-Json
    }

    Write-Host "Header:"
    Write-Host (Get-ConvertOutput -data (Get-Base64encode -data $tokenSplit[0]))
    Write-Host ""
    Write-Host "Payload:"
    Write-Host (Get-ConvertOutput -data (Get-Base64encode -data $tokenSplit[1]))
    Write-Host ""
    Write-Host "Signarure:"
    Write-Host $tokenSplit[2]
}

Export-ModuleMember -Function jwtd
