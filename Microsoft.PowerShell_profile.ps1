
function prompt {
    Import-Module posh-git
    Set-PSReadlineKeyHandler -Chord Tab -Function MenuComplete

    #Assign Windows Title Text
    # $host.ui.RawUI.WindowTitle = "Current Folder: $pwd"

    #Configure current user, current folder and date outputs
    $CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent().Name.split("\")[1];
    $CurrentComputer = [System.Net.Dns]::GetHostName();
    $CmdPromptUserAndComputer = "$CurrentUser@$CurrentComputer"

    $currentFolder = "$(Get-Location)";

    if($currentFolder -like "*$CurrentUser*"){
        $currentFolder = -join ("~", $currentFolder.Split("$CurrentUser")[1])
    }
    # $Date = Get-Date -Format "dd-MM-yy HH:mm:ss"

    # Test for Admin / Elevated
    $IsAdmin = (New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)

    #Calculate execution time of last cmd and convert to milliseconds, seconds or minutes
    # $LastCommand = Get-History -Count 1
    # if ($lastCommand) { $RunTime = ($lastCommand.EndExecutionTime - $lastCommand.StartExecutionTime).TotalSeconds }

    # if ($RunTime -ge 60) {
    #     $ts = [timespan]::fromseconds($RunTime)
    #     $min, $sec = ($ts.ToString("mm\:ss")).Split(":")
    #     $ElapsedTime = -join ($min, " min ", $sec, " sec")
    # }
    # else {
    #     $ElapsedTime = [math]::Round(($RunTime), 2)
    #     $ElapsedTime = -join (($ElapsedTime.ToString()), " sec")
    # }

    # Listen for azure subscription change
    $lastCommand = Get-History -Count 1
    if($lastCommand -like "az account set --subscription *"){
        $_ = Get-CachedOperation -Name azureSubscription -Command {az account show --query name} -Force
    }

    #Decorate the CMD Prompt
    Write-Host ""
    # Write-Host "$date" -NoNewline


    Write-Host ($(if ($IsAdmin) { 'Elevated ' } else { '' })) -BackgroundColor DarkRed -ForegroundColor White -NoNewline
    Write-Host "$CmdPromptUserAndComputer " -ForegroundColor DarkGreen -NoNewline
    Write-Host "$currentFolder " -ForegroundColor Blue -NoNewline

    $gitBranch = git rev-parse --abbrev-ref HEAD
    if ($gitBranch){
        Write-Host "($gitBranch) " -NoNewline -ForegroundColor Cyan

        $azureSubscription = Get-CachedOperation -Name azureSubscription -Command {az account show --query name}
        $azureSubscription = $azureSubscription.Trim('"')
        if($azureSubscription -like "*prod*"){
            Write-Host "[$azureSubscription] " -NoNewline -ForegroundColor DarkRed
        }
        else{
            Write-Host "[$azureSubscription] " -NoNewline -ForegroundColor Yellow
        }
    }

    Write-Host ""
    # Write-Host "[$elapsedTime] " -NoNewline -ForegroundColor Green
    return "$ "
} #end prompt function

function Get-CachedOperation([String]$Name, [ScriptBlock]$Command, [Switch]$Force){
   $CommandName = "cached_$($Name)"
   $cachedResults = Get-Variable -Scope Global -Name $CommandName -ErrorAction SilentlyContinue | Select -ExpandProperty Value
   $cacheTime = New-TimeSpan -Hours 1
   if($force -or $null -eq $cachedResults ){
        $CachedOperation = [CachedOperation]::new($Name, $command)
        New-Variable -Scope Global -Name $CommandName -value $CachedOperation -Force
        $cachedResults = $CachedOperation
   }
   
#    if([DateTime]::UtcNow -ge $cachedResults.TimeStamp + $cacheTime){
#        return Get-CachedOperation -Name $Name -Command $Command -Force
#    }
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