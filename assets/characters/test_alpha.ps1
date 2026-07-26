Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_2.png")
Write-Host "Pixel at (10,10): A=$($src.GetPixel(10,10).A) R=$($src.GetPixel(10,10).R) G=$($src.GetPixel(10,10).G) B=$($src.GetPixel(10,10).B)"
Write-Host "Pixel at (300,200): A=$($src.GetPixel(300,200).A) R=$($src.GetPixel(300,200).R) G=$($src.GetPixel(300,200).G) B=$($src.GetPixel(300,200).B)"
$src.Dispose()
