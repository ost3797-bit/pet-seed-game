Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_2.png")

$x_centers = @(745, 1175, 1605, 2045)
$y_centers = @(295, 630, 980, 1335)

for ($r=0; $r -lt 4; $r++) {
    for ($c=0; $c -lt 4; $c++) {
        $cx = $x_centers[$c]; $cy = $y_centers[$r]
        $min_x = 10000; $max_x = -10000; $min_y = 10000; $max_y = -10000
        for ($iy=-160; $iy -le 160; $iy++) {
            for ($ix=-140; $ix -le 140; $ix++) {
                $p = $src.GetPixel($cx+$ix, $cy+$iy)
                # 채도가 낮은 무채색 회색/흰색(체크보드 및 그 그림자) 제외
                $is_bg = (($p.R -ge 120) -and ([math]::Abs($p.R - $p.G) -le 20) -and ([math]::Abs($p.G - $p.B) -le 20))
                if (!$is_bg) {
                    if (($cx+$ix) -lt $min_x) { $min_x = $cx+$ix }
                    if (($cx+$ix) -gt $max_x) { $max_x = $cx+$ix }
                    if (($cy+$iy) -lt $min_y) { $min_y = $cy+$iy }
                    if (($cy+$iy) -gt $max_y) { $max_y = $cy+$iy }
                }
            }
        }
        Write-Host "Row $r Col $c : w=$($max_x - $min_x + 1), h=$($max_y - $min_y + 1)"
    }
}
$src.Dispose()
