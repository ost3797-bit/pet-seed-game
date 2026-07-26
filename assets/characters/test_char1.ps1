Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_1.png")
$cx = 451; $cy = 167
$p = $bmp.GetPixel($cx, $cy)
Write-Host "character_1 center color at (451, 167): R=$($p.R) G=$($p.G) B=$($p.B)"
$bmp.Dispose()
