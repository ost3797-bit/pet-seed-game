Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_3.png")
for ($y=0; $y -lt $src.Height; $y += 20) {
    $cnt = 0
    for ($x=0; $x -lt $src.Width; $x += 10) {
        $p = $src.GetPixel($x, $y)
        if ($p.A -gt 10 -and -not ($p.R -gt 235 -and $p.G -gt 235 -and $p.B -gt 235)) {
            $cnt++
        }
    }
    if ($cnt -gt 0) { Write-Host "Y=${y}: count=${cnt}" }
}
$src.Dispose()
