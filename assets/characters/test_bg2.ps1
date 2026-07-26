Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_2.png")
Write-Host "Top-left colors:"
for ($x=0; $x -lt 200; $x+=20) {
    $p = $bmp.GetPixel($x, 10)
    Write-Host "x=$x : R=$($p.R) G=$($p.G) B=$($p.B)"
}
$bmp.Dispose()
