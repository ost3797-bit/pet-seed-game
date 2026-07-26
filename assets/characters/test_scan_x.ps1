Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_2.png")
Write-Host "Scanning horizontal positions of characters at y=150:"
for ($x=0; $x -lt $src.Width; $x+=10) {
    $p = $src.GetPixel($x, 150)
    $is_bg = ($p.R -ge 165 -and ([math]::Abs($p.R - $p.G) -le 12) -and ([math]::Abs($p.G - $p.B) -le 12))
    if (!$is_bg) {
        Write-Host -NoNewline "$x "
    }
}
Write-Host ""
$src.Dispose()
