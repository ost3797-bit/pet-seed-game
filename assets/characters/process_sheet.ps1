Add-Type -AssemblyName System.Drawing
function Process-Sheet($inPath, $outPath) {
    $src = [System.Drawing.Bitmap]::FromFile($inPath)
    $dst = New-Object System.Drawing.Bitmap(800, 800, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($dst)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.Dispose()

    $x_centers = @(451, 720, 1000, 1288)
    $y_centers = @(167, 388, 603, 821)
    $size = 180 # 180x180 크기로 추출

    for ($r=0; $r -lt 4; $r++) {
        for ($c=0; $c -lt 4; $c++) {
            $cx = $x_centers[$c]
            $cy = $y_centers[$r]
            
            # 180x180 임시 비트맵
            $cell = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            for ($iy=0; $iy -lt $size; $iy++) {
                for ($ix=0; $ix -lt $size; $ix++) {
                    $sx = $cx - 90 + $ix
                    $sy = $cy - 90 + $iy
                    if ($sx -ge 0 -and $sx -lt $src.Width -and $sy -ge 0 -and $sy -lt $src.Height) {
                        $cell.SetPixel($ix, $iy, $src.GetPixel($sx, $sy))
                    }
                }
            }
            
            # BFS Flood Fill로 가장자리부터 배경 투명화
            $visited = New-Object 'bool[,]' $size, $size
            $queue = New-Object System.Collections.Queue
            
            # 4면 가장자리 모두 큐에 추가
            for ($i=0; $i -lt $size; $i++) {
                $queue.Enqueue(@($i, 0)); $visited[$i, 0] = $true
                $queue.Enqueue(@($i, $size-1)); $visited[$i, $size-1] = $true
                $queue.Enqueue(@(0, $i)); $visited[0, $i] = $true
                $queue.Enqueue(@($size-1, $i)); $visited[$size-1, $i] = $true
            }
            
            while ($queue.Count -gt 0) {
                $pt = $queue.Dequeue()
                $qx = $pt[0]; $qy = $pt[1]
                $col = $cell.GetPixel($qx, $qy)
                
                # 밝은 배경색(베이지/흰색)이거나 점선 색상 등 판별
                # 배경 베이지색: R>235, G>230, B>220
                if ($col.R -ge 235 -and $col.G -ge 230 -and $col.B -ge 220) {
                    $cell.SetPixel($qx, $qy, [System.Drawing.Color]::Transparent)
                    
                    # 상하좌우 탐색
                    $dx = @(1, -1, 0, 0); $dy = @(0, 0, 1, -1)
                    for ($k=0; $k -lt 4; $k++) {
                        $nx = $qx + $dx[$k]; $ny = $qy + $dy[$k]
                        if ($nx -ge 0 -and $nx -lt $size -and $ny -ge 0 -and $ny -lt $size) {
                            if (!$visited[$nx, $ny]) {
                                $visited[$nx, $ny] = $true
                                $queue.Enqueue(@($nx, $ny))
                            }
                        }
                    }
                }
            }
            
            # dst 800x800의 (c*200 + 10, r*200 + 10) 위치에 180x180 셀 복사
            $dest_x = $c * 200 + 10
            $dest_y = $r * 200 + 10
            for ($iy=0; $iy -lt $size; $iy++) {
                for ($ix=0; $ix -lt $size; $ix++) {
                    $col = $cell.GetPixel($ix, $iy)
                    if ($col.A -gt 0) {
                        $dst.SetPixel($dest_x + $ix, $dest_y + $iy, $col)
                    }
                }
            }
            $cell.Dispose()
        }
    }
    $src.Dispose()
    $dst.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $dst.Dispose()
    Write-Host "Processed and saved:" $outPath
}

Process-Sheet "c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_0.png" "c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\test_out_0.png"
