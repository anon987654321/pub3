# Continuous Dilla Chord Progression Playback - PowerShell
# Loops all chord progressions to local soundcard

$chordsDir = "G:\pub\multimedia\dilla\chords"
$chordFiles = @(
    "$chordsDir\blade_runner_dystopia.wav",
    "$chordsDir\midnight_ritual.wav",
    "$chordsDir\donuts_redux.wav",
    "$chordsDir\organic_dilla.wav",
    "$chordsDir\vienna_strings.wav",
    "$chordsDir\industrial_techno_dilla.wav"
)

Write-Host "Playing Dilla chords continuously..."
Write-Host "Press Ctrl+C to stop"

Add-Type -AssemblyName presentationCore
$mediaPlayer = New-Object System.Windows.Media.MediaPlayer

while ($true) {
    foreach ($file in $chordFiles) {
        if (Test-Path $file) {
            Write-Host "Now playing: $(Split-Path $file -Leaf)"
            $mediaPlayer.Open([uri]$file)
            $mediaPlayer.Play()

            # Wait for duration
            Start-Sleep -Milliseconds 500
            while ($mediaPlayer.NaturalDuration.HasTimeSpan -eq $false) {
                Start-Sleep -Milliseconds 100
            }
            Start-Sleep -Seconds $mediaPlayer.NaturalDuration.TimeSpan.TotalSeconds
        }
    }
}
