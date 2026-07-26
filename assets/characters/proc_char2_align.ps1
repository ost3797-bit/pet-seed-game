Add-Type -AssemblyName System.Drawing

function Process-Char2ToChar1($inPath, $outPath) {
    Write-Host "Processing $inPath -> $outPath with exact Bottom & Center alignment..."
    $src = [System.Drawing.Bitmap]::FromFile($inPath)
    
    # 4열 4행, 1칸당 가로 200, 세로 320 => 총 가로 800, 세로 1280
    $w = 200; $h = 320
    $dst = New-Object System.Drawing.Bitmap(($w * 4), ($h * 4), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($dst)
    $g.Clear([System.Drawing.Color]::Transparent)
    
    $x_centers = @(745, 1175, 1605, 2045)
    $y_centers = @(295, 630, 980, 1335)
    
    for ($r=0; $r -lt 4; $r++) {
        for ($c=0; $c -lt 4; $c++) {
            $cx = $x_centers[$c]; $cy = $y_centers[$r]
            
            # 1. 체크보드 제외 바운딩 박스 조사
            $min_x = 10000; $max_x = -10000; $min_y = 10000; $max_y = -10000
            for ($iy=-160; $iy -le 160; $iy++) {
                for ($ix=-140; $ix -le 140; $ix++) {
                    $sx = $cx + $ix; $sy = $cy + $iy
                    if ($sx -ge 0 -and $sx -lt $src.Width -and $sy -ge 0 -and $sy -lt $src.Height) {
                        $p = $src.GetPixel($sx, $sy)
                        $is_bg = (($p.R -ge 120) -and ([math]::Abs($p.R - $p.G) -le 20) -and ([math]::Abs($p.G - $p.B) -le 20))
                        if (!$is_bg) {
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
                
                # 2. 발바닥 정렬 (칸 하단에서 15px 위에 발바닥 max_y 배치) & 수평 중앙 정렬
                $dest_cell_x = $c * $w + [int](($w - $char_w) / 2)
                $dest_cell_y = ($r + 1) * $h - 15 - $char_h
                
                for ($y=$min_y; $y -le $max_y; $y++) {
                    for ($x=$min_x; $x -le $max_x; $x++) {
                        $p = $src.GetPixel($x, $y)
                        $is_bg = (($p.R -ge 120) -and ([math]::Abs($p.R - $p.G) -le 20) -and ([math]::Abs($p.G - $p.B) -le 20))
                        if (!$is_bg) {
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
    Write-Host "Successfully replaced and saved to $outPath !"
}

$dir = "c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters"
Process-Char2ToChar1 "$dir\character_2.png" "$dir\character_1.png"
