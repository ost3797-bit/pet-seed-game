Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_3.png")

$w = 200; $h = 300
$dst = New-Object System.Drawing.Bitmap(($w * 4), ($h * 4), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($dst)
$g.Clear([System.Drawing.Color]::Transparent)

# 16개 프레임의 정밀 바운딩 박스
$boxes = @(
    @{r=0; c=0; x1=375; x2=496; y1=66; y2=265},
    @{r=0; c=1; x1=694; x2=811; y1=69; y2=264},
    @{r=0; c=2; x1=965; x2=1083; y1=66; y2=264},
    @{r=0; c=3; x1=1207; x2=1323; y1=69; y2=265},
    @{r=1; c=0; x1=375; x2=483; y1=291; y2=488},
    @{r=1; c=1; x1=689; x2=795; y1=291; y2=489},
    @{r=1; c=2; x1=964; x2=1071; y1=291; y2=489},
    @{r=1; c=3; x1=1217; x2=1324; y1=291; y2=489},
    @{r=2; c=0; x1=378; x2=487; y1=518; y2=710},
    @{r=2; c=1; x1=682; x2=791; y1=518; y2=711},
    @{r=2; c=2; x1=958; x2=1067; y1=518; y2=708},
    @{r=2; c=3; x1=1209; x2=1318; y1=518; y2=704},
    @{r=3; c=0; x1=383; x2=494; y1=739; y2=935},
    @{r=3; c=1; x1=683; x2=792; y1=739; y2=935},
    @{r=3; c=2; x1=968; x2=1078; y1=739; y2=933},
    @{r=3; c=3; x1=1215; x2=1324; y1=739; y2=935}
)

foreach ($box in $boxes) {
    $r = $box.r; $c = $box.c
    $char_w = $box.x2 - $box.x1 + 1
    $char_h = $box.y2 - $box.y1 + 1
    
    # 각 칸(200x300)의 수평 중앙 & 하단에서 15px 위에 발바닥 접지!
    $dest_cell_x = $c * $w + [int](($w - $char_w) / 2)
    $dest_cell_y = ($r + 1) * $h - 15 - $char_h
    
    for ($y=$box.y1; $y -le $box.y2; $y++) {
        for ($x=$box.x1; $x -le $box.x2; $x++) {
            $p = $src.GetPixel($x, $y)
            # 흰색 배경 픽셀 제거 (R>230 & G>230 & B>230)
            if ($p.A -gt 10 -and -not ($p.R -gt 230 -and $p.G -gt 230 -and $p.B -gt 230)) {
                $dx = $dest_cell_x + ($x - $box.x1)
                $dy = $dest_cell_y + ($y - $box.y1)
                if ($dx -ge 0 -and $dx -lt $dst.Width -and $dy -ge 0 -and $dy -lt $dst.Height) {
                    $dst.SetPixel($dx, $dy, $p)
                }
            }
        }
    }
}

$g.Dispose()
$outPath = "c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_0_aligned.png"
$dst.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$dst.Dispose()
$src.Dispose()
Write-Host "Successfully generated character_0_aligned.png with perfect alignment and transparency!"
