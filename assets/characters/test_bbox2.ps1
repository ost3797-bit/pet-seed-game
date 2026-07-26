Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_2.png")

$cw = $src.Width / 4.0
$ch = $src.Height / 4.0

for ($r=0; $r -lt 1; $r++) {
    for ($c=0; $c -lt 2; $c++) {
        $min_x = 10000; $max_x = -10000; $min_y = 10000; $max_y = -10000
        $start_x = [int]($c * $cw)
        $end_x = [int](($c+1) * $cw - 1)
        $start_y = [int]($r * $ch)
        $end_y = [int](($r+1) * $ch - 1)
        
        for ($y=$start_y; $y -le $end_y; $y+=2) {
            for ($x=$start_x; $x -le $end_x; $x+=2) {
                $p = $src.GetPixel($x, $y)
                # 체크보드 판별: 회색/흰색 무채색(R>165 이고 R,G,B 차이가 12 이하)
                $is_bg = ($p.R -ge 165 -and ([math]::Abs($p.R - $p.G) -le 12) -and ([math]::Abs($p.G - $p.B) -le 12))
                if (!$is_bg) {
                    if ($x -lt $min_x) { $min_x = $x }
                    if ($x -gt $max_x) { $max_x = $x }
                    if ($y -lt $min_y) { $min_y = $y }
                    if ($y -gt $max_y) { $max_y = $y }
                }
            }
        }
        Write-Host "Row $r Col $c : BBox X($min_x to $max_x) Y($min_y to $max_y), w=$($max_x - $min_x), h=$($max_y - $min_y)"
    }
}
$src.Dispose()
