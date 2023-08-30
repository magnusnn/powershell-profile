### Assign Title Text
`$host.ui.RawUI.WindowTitle = "Current Folder: $pwd"`

### Date
`$Date = Get-Date -Format "dd-MM-yy HH:mm:ss"`

### Calculate execution time of last cmd and convert to milliseconds, seconds or minutes
``` 
$LastCommand = Get-History -Count 1
if ($lastCommand) { $RunTime = ($lastCommand.EndExecutionTime - $lastCommand.StartExecutionTime).TotalSeconds }

if ($RunTime -ge 60) {
    $ts = [timespan]::fromseconds($RunTime)
    $min, $sec = ($ts.ToString("mm\:ss")).Split(":")
    $ElapsedTime = -join ($min, " min ", $sec, " sec")
}
else {
    $ElapsedTime = [math]::Round(($RunTime), 2)
    $ElapsedTime = -join (($ElapsedTime.ToString()), " sec")
}
```

### Setting cache as variable in global scope
```
function Get-CachedOperation([String]$Name, [ScriptBlock]$Command, [Switch]$Force){
    $CommandName = "cached_$($Name)"
    $cachedResults = Get-Variable -Scope Global -Name $CommandName -ErrorAction SilentlyContinue | Select -ExpandProperty Value
    if ($null -eq $cachedResults){
        $cachedResults = Get-CachedOperationFromFile($Name)
    }

    if($force -or $null -eq $cachedResults){
        $cachedResults = [CachedOperation]::new($Name, $command)
        New-Variable -Scope Global -Name $CommandName -value $cachedResults -Force
        Set-CachedOperation($cachedResults)
    }

    return $cachedResults.Value
}
```

### Docker stuff
```
$DOCKER_DISTRO = "Ubuntu"
function docker {
    wsl -d $DOCKER_DISTRO docker -H unix:///mnt/wsl/shared-docker/docker.sock @Args
}

function docker-compose {
    wsl -d $DOCKER_DISTRO docker-compose -H unix:///mnt/wsl/shared-docker/docker.sock @Args
}
```

