Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_2.png")
Write-Host "Scanning vertical positions of characters at x=745:"
for ($y=0; $y -lt $src.Height; $y+=10) {
    $p = $src.GetPixel(745, $y)
    $is_bg = ($p.R -ge 165 -and ([math]::Abs($p.R - $p.G) -le 12) -and ([math]::Abs($p.G - $p.B) -le 12))
    if (!$is_bg) {
        Write-Host -NoNewline "$y "
    }
}
Write-Host ""
$src.Dispose()
