
function prompt {
    Set-PSReadlineKeyHandler -Chord Tab -Function MenuComplete

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

    # Test for Admin / Elevated
    $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

    # Listen for azure subscription change
    $lastCommand = Get-History -Count 1
    if($lastCommand -like "az account set *"){
        $_ = Get-CachedOperation -Name azureSubscription -Command {az account show --query name} -Force
    }

    #Decorate the CMD Prompt
    Write-Host ""

    Write-Host ($(if ($IsAdmin) { 'Admin ' } else { '' })) -BackgroundColor DarkRed -ForegroundColor White -NoNewline
    Write-Host "$CmdPromptUserAndComputer " -ForegroundColor DarkGreen -NoNewline
    Write-Host "$currentFolder " -ForegroundColor Blue -NoNewline

    $gitBranch = git rev-parse --abbrev-ref HEAD
    if ($gitBranch){
        Write-Host "($gitBranch) " -NoNewline -ForegroundColor Cyan
        
        if (Get-Command "az" -errorAction SilentlyContinue)
        {
            $azureSubscription = Get-CachedOperation -Name azureSubscription -Command {az account show --query name}
            $azureSubscription = $azureSubscription.Trim('"')
            if($azureSubscription -like "*prod*"){
                Write-Host "[$azureSubscription] " -NoNewline -ForegroundColor DarkRed
            }
            else{
                Write-Host "[$azureSubscription] " -NoNewline -ForegroundColor Yellow
            }
            
        }
    }

    Write-Host ""
    return "$ "
}

function Get-CachedOperation([String]$Name, [ScriptBlock]$Command, [Switch]$Force){
   $CommandName = "cached_$($Name)"
   $cachedResults = Get-Variable -Scope Global -Name $CommandName -ErrorAction SilentlyContinue | Select -ExpandProperty Value
   $cacheTime = New-TimeSpan -Hours 1
   if($force -or $null -eq $cachedResults ){
        $CachedOperation = [CachedOperation]::new($Name, $command)
        New-Variable -Scope Global -Name $CommandName -value $CachedOperation -Force
        $cachedResults = $CachedOperation
   }

   return $cachedResults.Value
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

}