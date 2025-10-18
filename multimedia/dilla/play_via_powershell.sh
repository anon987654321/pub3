#!/usr/bin/bash
# Play WAV via PowerShell MediaPlayer from Cygwin

WAVFILE="G:\\pub\\multimedia\\dilla\\temp_chord.wav"

powershell.exe -Command "
Add-Type -AssemblyName presentationCore
\$player = New-Object System.Windows.Media.MediaPlayer
\$player.Volume = 1.0
Write-Host 'Playing Dilla chords continuously...'
while (\$true) {
  \$player.Open([uri]'$WAVFILE')
  \$player.Play()
  Start-Sleep -Milliseconds 500
  while (-not \$player.NaturalDuration.HasTimeSpan) { Start-Sleep -Milliseconds 100 }
  Start-Sleep -Seconds \$player.NaturalDuration.TimeSpan.TotalSeconds
  \$player.Stop()
}
"
