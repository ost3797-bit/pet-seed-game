Add-Type -AssemblyName System.Drawing

function Process-Char0Align($inPath, $outPath) {
    Write-Host "Processing $inPath -> $outPath with exact Bottom & Center alignment..."
    $src = [System.Drawing.Bitmap]::FromFile($inPath)
    
    # 4열 4행, 1칸당 가로 140, 세로 180 => 총 가로 560, 세로 720
    $w = 140; $h = 180
    $dst = New-Object System.Drawing.Bitmap(($w * 4), ($h * 4), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($dst)
    $g.Clear([System.Drawing.Color]::Transparent)
    
    $x_centers = @(451, 720, 1000, 1288)
    $y_centers = @(167, 388, 603, 821)
    
    for ($r=0; $r -lt 4; $r++) {
        for ($c=0; $c -lt 4; $c++) {
            $cx = $x_centers[$c]; $cy = $y_centers[$r]
            
            # 바운딩 박스 조사
            $min_x = 10000; $max_x = -10000; $min_y = 10000; $max_y = -10000
            for ($iy=-80; $iy -le 80; $iy++) {
                for ($ix=-70; $ix -le 70; $ix++) {
                    $sx = $cx + $ix; $sy = $cy + $iy
                    if ($sx -ge 0 -and $sx -lt $src.Width -and $sy -ge 0 -and $sy -lt $src.Height) {
                        $p = $src.GetPixel($sx, $sy)
                        if (!($p.R -ge 235 -and $p.G -ge 230 -and $p.B -ge 215)) {
                            if ($sx -lt $min_x) { $min_x = $sx }
                            if ($sx -gt $max_x) { $max_x = $sx }
                            if ($sy -lt $min_y) { $min_y = $sy }
                            if ($sy -gt $max_y) { $max_y = $sy }
                        }
                    }
                }
            }
            
            if ($min_x -le $max_x) {
                $char_w = $max_x - $min_x + 1
                $char_h = $max_y - $min_y + 1
                
                # 발바닥 정렬(칸 하단 10px 위에 배치) & 수평 중앙 정렬
                $dest_cell_x = $c * $w + [int](($w - $char_w) / 2)
                $dest_cell_y = ($r + 1) * $h - 10 - $char_h
                
                for ($y=$min_y; $y -le $max_y; $y++) {
                    for ($x=$min_x; $x -le $max_x; $x++) {
                        $p = $src.GetPixel($x, $y)
                        if (!($p.R -ge 235 -and $p.G -ge 230 -and $p.B -ge 215)) {
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
    $g.Dispose()
    $tmpPath = $outPath + ".tmp.png"
    $dst.Save($tmpPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $dst.Dispose()
    $src.Dispose()
    
    if (Test-Path $outPath) { Remove-Item $outPath -Force }
    Rename-Item $tmpPath (Split-Path $outPath -Leaf) -Force
    Write-Host "Successfully aligned and saved to $outPath !"
}

$dir = "c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters"
Process-Char0Align "$dir\character_0_orig.png" "$dir\character_0.png"
