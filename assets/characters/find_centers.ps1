Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_0.png")

$x_centers = @(470, 760, 1050, 1340)
$y_centers = @(170, 390, 610, 830)

for ($r=0; $r -lt 4; $r++) {
    for ($c=0; $c -lt 4; $c++) {
        $cx = $x_centers[$c]
        $cy = $y_centers[$r]
        $sum_x = 0; $sum_y = 0; $count = 0
        for ($y=$cy-80; $y -le $cy+80; $y++) {
            for ($x=$cx-80; $x -le $cx+80; $x++) {
                $p = $bmp.GetPixel($x, $y)
                # 배경색(밝은 아이보리/베이지/흰색)이 아니면서 회색 점선/테두리선이 아닌 픽셀 판별
                # 캐릭터는 갈색 머리, 짙은 파랑 옷, 살구색 피부 등 색상이 풍부하거나 어두움
                if ($p.R -lt 230 -or $p.G -lt 230 -or $p.B -lt 230) {
                    # 회색 점선/갈색 외곽선 제거: 너무 가장자리(x나 y가 끝쪽)이거나 색상이 단조로운 선 제외
                    $sum_x += $x
                    $sum_y += $y
                    $count++
                }
            }
        }
        if ($count -gt 0) {
            $avg_x = [int]($sum_x / $count)
            $avg_y = [int]($sum_y / $count)
            Write-Host "Row $r Col $c : Center ($avg_x, $avg_y), count=$count"
        } else {
            Write-Host "Row $r Col $c : Not found"
        }
    }
}
$bmp.Dispose()
