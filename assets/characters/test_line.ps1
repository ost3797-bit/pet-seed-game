Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_0.png")
$cx = 451; $cy = 167
Write-Host "--- Horizontal from cx-80 to cx+80 at y=$cy ---"
for ($x=$cx-80; $x -le $cx+80; $x+=5) {
    $p = $bmp.GetPixel($x, $cy)
    if (!($p.R -ge 230 -and $p.G -ge 230 -and $p.B -ge 230)) {
        Write-Host "x=$x : R=$($p.R) G=$($p.G) B=$($p.B)"
    }
}
Write-Host "--- Vertical from cy-80 to cy+80 at x=$cx ---"
for ($y=$cy-80; $y -le $cy+80; $y+=5) {
    $p = $bmp.GetPixel($cx, $y)
    if (!($p.R -ge 230 -and $p.G -ge 230 -and $p.B -ge 230)) {
        Write-Host "y=$y : R=$($p.R) G=$($p.G) B=$($p.B)"
    }
}
$bmp.Dispose()
