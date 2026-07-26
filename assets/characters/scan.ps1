Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_0.png")
for ($x=0; $x -lt $bmp.Width; $x+=150) {
    $c = $bmp.GetPixel($x, 500)
    Write-Host "x=$x : R=$($c.R) G=$($c.G) B=$($c.B)"
}
for ($y=0; $y -lt $bmp.Height; $y+=100) {
    $c = $bmp.GetPixel(700, $y)
    Write-Host "y=$y : R=$($c.R) G=$($c.G) B=$($c.B)"
}
$bmp.Dispose()
