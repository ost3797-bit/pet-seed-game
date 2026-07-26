Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_2.png")
for ($x=660; $x -le 1260; $x+=50) {
    $p = $src.GetPixel($x, 150)
    $is_bg = ($p.R -ge 165 -and ([math]::Abs($p.R - $p.G) -le 12) -and ([math]::Abs($p.G - $p.B) -le 12))
    if (!$is_bg) {
        Write-Host "Not BG at x=$x : R=$($p.R) G=$($p.G) B=$($p.B)"
    }
}
$src.Dispose()
