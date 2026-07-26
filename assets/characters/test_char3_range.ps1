Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_3.png")
Write-Host "Total size: $($src.Width) x $($src.Height)"
# 수평으로 픽셀이 있는 X 좌표 범위 확인
$min_x = 10000; $max_x = -10000
for ($x=0; $x -lt $src.Width; $x += 10) {
    for ($y=0; $y -lt $src.Height; $y += 10) {
        $p = $src.GetPixel($x, $y)
        if ($p.A -gt 10 -and -not ($p.R -gt 235 -and $p.G -gt 235 -and $p.B -gt 235)) {
            if ($x -lt $min_x) { $min_x = $x }
            if ($x -gt $max_x) { $max_x = $x }
        }
    }
}
Write-Host "X range with non-white pixels: $min_x to $max_x"
$src.Dispose()
