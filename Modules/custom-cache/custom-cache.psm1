function CheckIfCacheIsUpdated([CachedOperation[]] $CachedOperations){
    function PrintCacheUpdated([string] $Name){
        Write-Host ""
        Write-Host "Refreshed cache for '$Name' 🚀" -NoNewline -ForegroundColor DarkGray
    }

    foreach ($operation in $CachedOperations){
        if($operation.CacheUpdated){
            PrintCacheUpdated -Name $operation.Name
        }
    }
}

function Get-CachedOperationFromFile([string] $name){
    $destination_dir = "$($profile.Replace("\Microsoft.PowerShell_profile.ps1", ''))\cache\"
    if(Test-Path "$destination_dir\$name"){
        $file_value = Get-Content -Path "$destination_dir\$name"
        return [CachedOperation]::new($file_value)
    }

    return $null
}

function Set-CachedOperation([CachedOperation] $cache){
    $destination_dir = "$($profile.Replace("\Microsoft.PowerShell_profile.ps1", ''))\cache\"
    If(!(Test-Path $destination_dir)){
        New-Item -ItemType Directory -Force -Path $destination_dir
    }
    Set-Content "$destination_dir\$($cache.Name)" "$($cache.ToString())"
}

function Get-CachedOperation([String]$Name, [ScriptBlock]$Command, [Switch]$Force){
    $cachedResults = Get-CachedOperationFromFile($Name)

    if($force -or $null -eq $cachedResults -or $cachedResults.TimeStamp.AddDays(2) -lt [DateTime]::UtcNow){
        $cachedResults = [CachedOperation]::new($Name, $command, 1)
        Set-CachedOperation($cachedResults)
    }

    return $cachedResults
}

class CachedOperation
{
    # Automatic TimeStamp
    [DateTime] $TimeStamp;

    # Command Nickname
    [string] $Name;

    # Command Instructions
    [ScriptBlock] $Command;

    # Output, whatever it is
    [psCustomObject] $Value;

    [bool] $CacheUpdated;

    #Constructor
    CachedOperation ([string] $name, [ScriptBlock]$scriptblock, [bool]$cacheUpdated)
    {
        $this.TimeStamp = [DateTime]::UtcNow
        $this.Name = $name;
        $this.Command = $scriptblock
        $this.Value= $scriptblock.Invoke()
        $this.CacheUpdated = $cacheUpdated
    }

    CachedOperation([string] $string){
        $array = $string.split(";")
        $this.TimeStamp = $array.Get(0)
        $this.Name = $array.Get(1)
        $this.Command = [ScriptBlock]::Create($array.Get(2))
        $this.Value = $array.Get(3)
        $this.CacheUpdated = 0
    }

    [string]ToString(){
        return "$($this.TimeStamp);$($this.Name);$($this.Command);$($this.Value)"
    }
}

Export-ModuleMember -Function Get-CachedOperationFromFile
Export-ModuleMember -Function Set-CachedOperation
Export-ModuleMember -Function Get-CachedOperation
Export-ModuleMember -Function CheckIfCacheIsUpdated
