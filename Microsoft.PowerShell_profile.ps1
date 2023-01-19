using module custom-cache
using module custom-jwtd
using module custom-pscolor

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

    [CachedOperation]$azAccountShow = $null;
    [CachedOperation]$aksCurrentContext = $null;

    if($currentFolder -like "*$CurrentUser*"){
        $currentFolder = -join ("~", $currentFolder.Split("$CurrentUser")[1])
    }
    $Host.UI.RawUI.WindowTitle = "$currentFolder"
    Remove-Powershell73Colors
    Add-CustomListener

    #Decorate the CMD Prompt
    Write-Host ""
    Get-IsAdmin

    Write-Host "$CmdPromptUserAndComputer " -ForegroundColor DarkGreen -NoNewline
    Write-Host "$currentFolder " -ForegroundColor Blue -NoNewline

    Get-GitInformation
    Get-AzSubscription
    Get-KubernetesClusterInfo

    CheckIfCacheIsUpdated -CachedOperations @($azAccountShow, $aksCurrentContext)

    Write-Host ""
    return "$ "
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

function Get-IsAdmin{
     # Test for Admin / Elevated
    $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

    if ($IsAdmin){
        Write-Host "🚨" -NoNewline
        Write-Host "Admin" -BackgroundColor Red -ForegroundColor White -NoNewline
        Write-Host "🚨 " -NoNewline
    }
}

function Add-CustomListener{
    # Listen for azure subscription change
    $lastCommand = Get-History -Count 1
    if($lastCommand -like "az account set *"){
        $_ = Get-CachedOperation -Name azAccountShow -Command {az account show --query name} -Force
    }
    if($lastCommand -like "az aks get-credentials *" -or $lastCommand -like "kubectl config use-context *"){
        $_ = Get-CachedOperation -Name aksCurrentContext -Command {kubectl config view -o jsonpath='{.current-context}'} -Force
    }
}

function Get-GitInformation{
    $gitBranch = git rev-parse --abbrev-ref HEAD
    if ($gitBranch){
        Write-Host "($gitBranch) " -NoNewline -ForegroundColor Cyan
    }
}

function Get-AzSubscription{
    if (Get-Command "az" -errorAction SilentlyContinue)
    {
        $azAccountShow = Get-CachedOperation -Name azAccountShow -Command {az account show --query name}
        $azAccountShowValue = $azAccountShow.Value.Trim('"')
        if($azAccountShowValue -like "*prod*"){
            Write-Host "⚠️[$azAccountShowValue]⚠️ " -NoNewline -ForegroundColor DarkRed
        }
        else{
            Write-Host "[$azAccountShowValue] " -NoNewline -ForegroundColor Yellow
        }
    }
}

function Get-KubernetesClusterInfo{
    if (Get-Command "kubectl" -errorAction SilentlyContinue)
    {
        $aksCurrentContext = Get-CachedOperation -Name aksCurrentContext -Command {kubectl config view -o jsonpath='{.current-context}'}
        $aksCurrentContextValue = $aksCurrentContext.Value
        if($aksCurrentContextValue -like "*prod*")
        {
            Write-Host "⚠️[$aksCurrentContextValue]⚠️ " -NoNewline -ForegroundColor DarkRed
        }
        else
        {
            # $color = $currentContext.split("-")[-1]
            Write-Host "[$aksCurrentContextValue] " -NoNewline -ForegroundColor DarkYellow
        }
    }
}
