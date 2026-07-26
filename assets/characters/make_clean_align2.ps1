Add-Type -AssemblyName System.Drawing

$dir = "c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters"

function Process-AlignCleanNew2($inPath, $outPath) {
    Write-Host "Creating super clean sheet $outPath without red noise under shoes..."
    $src = [System.Drawing.Bitmap]::FromFile($inPath)
    
    $w = 200; $h = 300
    $dst = New-Object System.Drawing.Bitmap(($w * 4), ($h * 4), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($dst)
    $g.Clear([System.Drawing.Color]::Transparent)
    
    $cw = $src.Width / 4.0; $ch = $src.Height / 4.0
    
    for ($r=0; $r -lt 4; $r++) {
        for ($c=0; $c -lt 4; $c++) {
            $min_x = 10000; $max_x = -10000; $min_y = 10000; $max_y = -10000
            $start_x = [int]($c * $cw); $end_x = [int](($c+1) * $cw - 1)
            # 아래칸 캐릭터의 리본 침범을 막기 위해 end_y를 6픽셀 여유 있게 줄임
            $start_y = [int]($r * $ch); $end_y = [int](($r+1) * $ch - 6)
            
            for ($iy=$start_y; $iy -le $end_y; $iy++) {
                for ($ix=$start_x; $ix -le $end_x; $ix++) {
                    $p = $src.GetPixel($ix, $iy)
                    if ($p.A -gt 10) {
                        # 신발 부근(칸 아래쪽 15% 영역)의 삐져나온 빨간색 리본 픽셀은 바운딩 박스 및 복사에서 제외
                        $is_lower_part = ($iy -gt ($start_y + $ch * 0.75))
                        $is_red_noise = ($is_lower_part -and $p.R -gt 150 -and $p.G -lt 100 -and $p.B -lt 100)
                        if (!$is_red_noise) {
                            if ($ix -lt $min_x) { $min_x = $ix }
                            if ($ix -gt $max_x) { $max_x = $ix }
                            if ($iy -lt $min_y) { $min_y = $iy }
                            if ($iy -gt $max_y) { $max_y = $iy }
                        }
                    }
                }
            }
            
            if ($min_x -le $max_x) {
                $char_w = $max_x - $min_x + 1
                $char_h = $max_y - $min_y + 1
                
                # 발바닥 정렬 (칸 하단에서 15px 위에 발바닥 안착) & 수평 중앙 정렬
                $dest_cell_x = $c * $w + [int](($w - $char_w) / 2)
                $dest_cell_y = ($r + 1) * $h - 15 - $char_h
                
                for ($y=$min_y; $y -le $max_y; $y++) {
                    for ($x=$min_x; $x -le $max_x; $x++) {
                        $p = $src.GetPixel($x, $y)
                        if ($p.A -gt 10) {
                            $is_lower_part = ($y -gt ($start_y + $ch * 0.75))
                            $is_red_noise = ($is_lower_part -and $p.R -gt 150 -and $p.G -lt 100 -and $p.B -lt 100)
                            if (!$is_red_noise) {
                                $dx = $dest_cell_x + ($x - $min_x)
                                $dy = $dest_cell_y + ($y - $min_y)
                                if ($dx -ge 0 -and $dx -lt $dst.Width -and $dy -ge 0 -and $dy -lt $dst.Height) {
                                    $dst.SetPixel($dx, $dy, $p)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    $g.Dispose()
    $dst.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $dst.Dispose()
    $src.Dispose()
    Write-Host "Successfully generated clean sheet without red shoe noise!"
}

Process-AlignCleanNew2 "$dir\character_2.png" "$dir\character_2_aligned.png"
