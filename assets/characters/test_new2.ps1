Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_2.png")

$cw = $src.Width / 4.0
$ch = $src.Height / 4.0

for ($r=0; $r -lt 4; $r++) {
    for ($c=0; $c -lt 4; $c++) {
        $min_x = 10000; $max_x = -10000; $min_y = 10000; $max_y = -10000
        $start_x = [int]($c * $cw); $end_x = [int](($c+1) * $cw - 1)
        $start_y = [int]($r * $ch); $end_y = [int](($r+1) * $ch - 1)
        
        for ($y=$start_y; $y -le $end_y; $y++) {
            for ($x=$start_x; $x -le $end_x; $x++) {
                $p = $src.GetPixel($x, $y)
                if ($p.A -gt 10) { # 투명이 아닌 캐릭터 픽셀
                    if ($x -lt $min_x) { $min_x = $x }
                    if ($x -gt $max_x) { $max_x = $x }
                    if ($y -lt $min_y) { $min_y = $y }
                    if ($y -gt $max_y) { $max_y = $y }
                }
            }
        }
        if ($min_x -le $max_x) {
            Write-Host "Row $r Col $c : BBox X($min_x to $max_x) Y($min_y to $max_y), w=$($max_x - $min_x + 1), h=$($max_y - $min_y + 1)"
        } else {
            Write-Host "Row $r Col $c : Empty"
        }
    }
}
$src.Dispose()
