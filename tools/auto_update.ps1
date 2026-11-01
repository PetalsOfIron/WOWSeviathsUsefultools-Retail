# Runs tools/update_data.py by itself every time the game writes the addon's saved data: after each /reload, each logout and each exit.
# It watches the saved-data file, waits until the game has finished writing it, then bakes the data, pushes it to Data-wow and rebuilds the zip.
# Started at logon by a scheduled task (see tools/README-auto-update.txt); it waits in the background and costs nothing while idle.
$py = "C:\Python315\python.exe"
$script = Join-Path $PSScriptRoot "update_data.py"
$saved = Get-ChildItem "D:\wow\World of Warcraft\_retail_\WTF\Account\*\SavedVariables\SeviathsUsefulTools.lua" | Select-Object -First 1
$log = Join-Path $env:USERPROFILE "Projects\sut-curse-release\auto_update.log"
$last = if ($saved) { $saved.LastWriteTimeUtc } else { [datetime]::MinValue }
# once when it starts (when the game is opened with the launcher): what the last session saved is baked at once
"[$(Get-Date -Format s)] watcher started: updating" | Add-Content $log
& $py $script *>> $log
"[$(Get-Date -Format s)] done" | Add-Content $log
while ($true) {
    Start-Sleep -Seconds 20
    if (-not $saved) { continue }
    $saved.Refresh()
    if ($saved.LastWriteTimeUtc -gt $last) {
        # the file is still being written: wait until it has not changed for 20 seconds
        do { $stamp = $saved.LastWriteTimeUtc; Start-Sleep -Seconds 20; $saved.Refresh() } while ($saved.LastWriteTimeUtc -ne $stamp)
        $last = $saved.LastWriteTimeUtc
        "[$(Get-Date -Format s)] saved data changed: updating" | Add-Content $log
        & $py $script *>> $log
        "[$(Get-Date -Format s)] done" | Add-Content $log
    }
}
