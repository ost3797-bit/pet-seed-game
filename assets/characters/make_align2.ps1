Add-Type -AssemblyName System.Drawing

$dir = "c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters"

# 1. 문제의 고도 엔진 캐시 유발 구버전 character_1.png 및 import 삭제
if (Test-Path "$dir\character_1.png") { Remove-Item "$dir\character_1.png" -Force }
if (Test-Path "$dir\character_1.png.import") { Remove-Item "$dir\character_1.png.import" -Force }

# 2. 새로 올린 투명 원본 character_2.png를 가공하여 고도 엔진이 새로 인식할 character_2_aligned.png 생성
function Process-AlignNew2($inPath, $outPath) {
    Write-Host "Creating clean new sheet $outPath from $inPath ..."
    $src = [System.Drawing.Bitmap]::FromFile($inPath)
    
    # 4열 4행, 1칸당 가로 200, 세로 300 => 총 가로 800, 세로 1200
    $w = 200; $h = 300
    $dst = New-Object System.Drawing.Bitmap(($w * 4), ($h * 4), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($dst)
    $g.Clear([System.Drawing.Color]::Transparent)
    
    $cw = $src.Width / 4.0; $ch = $src.Height / 4.0
    
    for ($r=0; $r -lt 4; $r++) {
        for ($c=0; $c -lt 4; $c++) {
            $min_x = 10000; $max_x = -10000; $min_y = 10000; $max_y = -10000
            $start_x = [int]($c * $cw); $end_x = [int](($c+1) * $cw - 1)
            $start_y = [int]($r * $ch); $end_y = [int](($r+1) * $ch - 1)
            
            for ($iy=$start_y; $iy -le $end_y; $iy++) {
                for ($ix=$start_x; $ix -le $end_x; $ix++) {
                    $p = $src.GetPixel($ix, $iy)
                    if ($p.A -gt 10) {
                        if ($ix -lt $min_x) { $min_x = $ix }
                        if ($ix -gt $max_x) { $max_x = $ix }
                        if ($iy -lt $min_y) { $min_y = $iy }
                        if ($iy -gt $max_y) { $max_y = $iy }
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
    $dst.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $dst.Dispose()
    $src.Dispose()
    Write-Host "Saved to $outPath successfully!"
}

Process-AlignNew2 "$dir\character_2.png" "$dir\character_2_aligned.png"
