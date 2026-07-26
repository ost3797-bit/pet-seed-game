Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_3.png")
Write-Host "크기: $($src.Width) x $($src.Height)"
Write-Host "셀 크기(추정): $($src.Width / 4.0) x $($src.Height / 4.0)"

# 배경색 샘플링
Write-Host "모서리 픽셀 0,0: $($src.GetPixel(0,0))"
Write-Host "모서리 픽셀 5,5: $($src.GetPixel(5,5))"
$src.Dispose()
