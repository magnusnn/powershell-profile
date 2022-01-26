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

