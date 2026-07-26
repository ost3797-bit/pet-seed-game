Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_3.png")
$cw = $src.Width / 4.0; $ch = $src.Height / 4.0
for ($r=0; $r -lt 4; $r++) {
    for ($c=0; $c -lt 4; $c++) {
        $min_x = 10000; $max_x = -10000; $min_y = 10000; $max_y = -10000
        $start_x = [int]($c * $cw); $end_x = [int](($c+1) * $cw - 1)
        $start_y = [int]($r * $ch); $end_y = [int](($r+1) * $ch - 1)
        for ($iy=$start_y; $iy -le $end_y; $iy++) {
            for ($ix=$start_x; $ix -le $end_x; $ix++) {
                $p = $src.GetPixel($ix, $iy)
                # 흰색이나 연한 배경(R>230, G>230, B>230 등) 제외
                if ($p.A -gt 10 -and -not ($p.R -gt 235 -and $p.G -gt 235 -and $p.B -gt 235)) {
                    if ($ix -lt $min_x) { $min_x = $ix }
                    if ($ix -gt $max_x) { $max_x = $ix }
                    if ($iy -lt $min_y) { $min_y = $iy }
                    if ($iy -gt $max_y) { $max_y = $iy }
                }
            }
        }
        if ($min_x -le $max_x) {
            Write-Host "Row ${r} Col ${c}: w=$($max_x-$min_x+1), h=$($max_y-$min_y+1), bottom_margin=$($end_y - $max_y)"
        } else {
            Write-Host "Row ${r} Col ${c}: EMPTY"
        }
    }
}
$src.Dispose()
