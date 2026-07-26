Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_3.png")
Write-Host "크기: $($src.Width) x $($src.Height)"
Write-Host "셀 크기: $($src.Width / 4.0) x $($src.Height / 4.0)"

# 4행 X 범위 탐색
$row_bounds = @(
    @{min_y=0; max_y=[int]($src.Height/4.0)-1},
    @{min_y=[int]($src.Height/4.0); max_y=[int]($src.Height/4.0*2)-1},
    @{min_y=[int]($src.Height/4.0*2); max_y=[int]($src.Height/4.0*3)-1},
    @{min_y=[int]($src.Height/4.0*3); max_y=$src.Height-1}
)

for ($r=0; $r -lt 4; $r++) {
    $rmin = $row_bounds[$r].min_y; $rmax = $row_bounds[$r].max_y
    $in_char = $false; $char_start = 0; $chars = @()
    for ($x=0; $x -lt $src.Width; $x++) {
        $has_pixel = $false
        for ($y=$rmin; $y -le $rmax; $y += 3) {
            $p = $src.GetPixel($x, $y)
            if ($p.A -gt 30 -and -not ($p.R -gt 230 -and $p.G -gt 230 -and $p.B -gt 230)) {
                $has_pixel = $true; break
            }
        }
        if ($has_pixel -and !$in_char) { $in_char = $true; $char_start = $x }
        elseif (!$has_pixel -and $in_char) {
            if (($x - $char_start) -gt 20) { $chars += @{start=$char_start; end=$x-1} }
            $in_char = $false
        }
    }
    if ($in_char -and (($src.Width - $char_start) -gt 20)) { $chars += @{start=$char_start; end=$src.Width-1} }
    
    for ($c=0; $c -lt $chars.Count; $c++) {
        $cx1 = $chars[$c].start; $cx2 = $chars[$c].end
        $cy1 = 10000; $cy2 = -10000
        for ($iy=$rmin; $iy -le $rmax; $iy++) {
            for ($ix=$cx1; $ix -le $cx2; $ix++) {
                $p = $src.GetPixel($ix, $iy)
                if ($p.A -gt 30 -and -not ($p.R -gt 230 -and $p.G -gt 230 -and $p.B -gt 230)) {
                    if ($iy -lt $cy1) { $cy1 = $iy }
                    if ($iy -gt $cy2) { $cy2 = $iy }
                }
            }
        }
        Write-Host "Row ${r} Col ${c}: X=($cx1~$cx2, w=$($cx2-$cx1+1)), Y=($cy1~$cy2, h=$($cy2-$cy1+1))"
    }
}
$src.Dispose()
