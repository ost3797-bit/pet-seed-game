Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_0.png")

$cx = 451; $cy = 167
$min_x = 10000; $max_x = -10000; $min_y = 10000; $max_y = -10000
for ($y=$cy-80; $y -le $cy+80; $y++) {
    for ($x=$cx-80; $x -le $cx+80; $x++) {
        $p = $bmp.GetPixel($x, $y)
        # 배경색 판별 (R,G,B 가 모두 230 이상이면 흰색/아이보리 배경)
        if (!($p.R -ge 230 -and $p.G -ge 230 -and $p.B -ge 230)) {
            if ($x -lt $min_x) { $min_x = $x }
            if ($x -gt $max_x) { $max_x = $x }
            if ($y -lt $min_y) { $min_y = $y }
            if ($y -gt $max_y) { $max_y = $y }
        }
    }
}
Write-Host "Bounding box for Row 0 Col 0: X($min_x to $max_x) Y($min_y to $max_y), width=$($max_x - $min_x + 1), height=$($max_y - $min_y + 1)"
$bmp.Dispose()
