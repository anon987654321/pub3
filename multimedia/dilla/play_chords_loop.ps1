# Play Dilla chords non-stop - PowerShell looper
$chords = Get-ChildItem "G:\pub\multimedia\dilla\chords\*.wav" | Select-Object -First 6

if ($chords.Count -eq 0) {
    Write-Host "No chord files found"
    exit 1
}

Add-Type -AssemblyName presentationCore
$player = New-Object System.Windows.Media.MediaPlayer
$player.Volume = 1.0

Write-Host "Playing Dilla chords non-stop (Ctrl+C to stop)..."
Write-Host ""

while ($true) {
    foreach ($file in $chords) {
        Write-Host "Playing: $($file.Name)"
        $player.Open([uri]$file.FullName)
        $player.Play()

        Start-Sleep -Milliseconds 500
        while (-not $player.NaturalDuration.HasTimeSpan) {
            Start-Sleep -Milliseconds 100
        }

        $duration = $player.NaturalDuration.TimeSpan.TotalSeconds
        Start-Sleep -Seconds $duration
        $player.Stop()
    }
}
