function Remove-Powershell73Colors{
    if ($psstyle) {
        $psstyle.FileInfo.Directory = $psstyle.FileInfo.Executable = $psstyle.FileInfo.SymbolicLink  = "" 
        $PSStyle.FileInfo.Extension.Clear()
        $PSStyle.Formatting.TableHeader       = ""
        $PsStyle.Formatting.FormatAccent      = ""
    }
}

Export-ModuleMember -Function Remove-Powershell73Colors
