
function prompt {
    # Imports
    Import-Module posh-git
    
    # Setting up PSReadLine
    Set-PSReadlineKeyHandler -Chord Tab -Function MenuComplete
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView

    # Autocomplete
    kubectl completion powershell | Out-String | Invoke-Expression

    # Add SSH-key
    Start-Service ssh-agent
    $sshKeysListed = $(ssh-add -l)
    if($sshKeysListed -like ""){
        $(ssh-add $PROFILE\.ssh\id_rsa)
    }

    #Configure current user, current folder and date outputs
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name.split("\")[1];
    $CurrentComputer = [System.Net.Dns]::GetHostName();
    $CmdPromptUserAndComputer = "$CurrentUser@$CurrentComputer"

    $currentFolder = "$(Get-Location)";

    if($currentFolder -like "*$CurrentUser*"){
        $currentFolder = -join ("~", $currentFolder.Split("$CurrentUser")[1])
    }
    $Host.UI.RawUI.WindowTitle = "$currentFolder"

    # Test for Admin / Elevated
    $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

    # Listen for azure subscription change
    $lastCommand = Get-History -Count 1
    if($lastCommand -like "az account set *"){
        $_ = Get-CachedOperation -Name azAccountShow -Command {az account show --query name} -Force
    }

    #Decorate the CMD Prompt
    Write-Host ""

    if ($IsAdmin){
        Write-Host "🚨" -NoNewline
        Write-Host "Admin" -BackgroundColor Red -ForegroundColor White -NoNewline
        Write-Host "🚨 " -NoNewline
    }

    Write-Host "$CmdPromptUserAndComputer " -ForegroundColor DarkGreen -NoNewline
    Write-Host "$currentFolder " -ForegroundColor Blue -NoNewline

    $gitBranch = git rev-parse --abbrev-ref HEAD
    if ($gitBranch){
        Write-Host "($gitBranch) " -NoNewline -ForegroundColor Cyan
    }

    if (Get-Command "az" -errorAction SilentlyContinue)
    {
        [CachedOperation]$azAccountShow, [bool]$cacheUpdated = Get-CachedOperation -Name azAccountShow -Command {az account show --query name}
        $azAccountShowValue = $azAccountShow.Value.Trim('"')
        if($azAccountShowValue -like "*prod*"){
            Write-Host "⚠️[$azAccountShowValue]⚠️ " -NoNewline -ForegroundColor DarkRed
        }
        else{
            Write-Host "[$azAccountShowValue] " -NoNewline -ForegroundColor Yellow
        }

        if($cacheUpdated){
            Write-Host ""
            Write-Host "Refreshed cache for '$($azAccountShow.Name)' 🚀" -NoNewline -ForegroundColor DarkGray
        }
    }

    if (Get-Command "kubectl" -errorAction SilentlyContinue)
    {
        $currentContext = kubectl config view -o jsonpath='{.current-context}'
        if($currentContext -Contains "prod")
        {
            Write-Host "⚠️[$currentContext]⚠️ " -NoNewline -ForegroundColor DarkRed
        }
        else
        {
            # $color = $currentContext.split("-")[-1]
            Write-Host "[$currentContext] " -NoNewline -ForegroundColor DarkYellow
        }
    }

    Write-Host ""
    return "$ "
}

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

function number-lookup([string] $number){
    start chrome "https://www.180.no/search/all?w=$($number)"
    # start chrome "https://www.1881.no/?query=$($number)"
}

function møterom([string] $floor){
    $destination_dir = "$($profile.Replace("\Microsoft.PowerShell_profile.ps1", ''))\romoversikt\"
    if($floor -eq "7"){
        start "$destination_dir\7.png"
    }
    
    start "$destination_dir\2.png"
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
    [bool]$cacheUpdated = 0

    if($force -or $null -eq $cachedResults -or $cachedResults.TimeStamp.AddDays(2) -lt [DateTime]::UtcNow){
        $cachedResults = [CachedOperation]::new($Name, $command)
        Set-CachedOperation($cachedResults)
        $cacheUpdated = 1
    }

    return $cachedResults, $cacheUpdated
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

    #Constructor
    CachedOperation ([string] $name, [ScriptBlock]$scriptblock)
    {
        $this.TimeStamp = [DateTime]::UtcNow
        $this.Name = $name;
        $this.Command = $scriptblock
        $this.Value= $scriptblock.Invoke()
    }

    CachedOperation([string] $string){
        $array = $string.split(";")
        $this.TimeStamp = $array.Get(0)
        $this.Name = $array.Get(1)
        $this.Command = [ScriptBlock]::Create($array.Get(2))
        $this.Value = $array.Get(3)
    }

    [string]ToString(){
        return "$($this.TimeStamp);$($this.Name);$($this.Command);$($this.Value)"
    }
}
