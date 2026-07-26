Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_2.png")

$w = 200; $h = 300
$dst = New-Object System.Drawing.Bitmap(($w*4),($h*4),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($dst)
$g.Clear([System.Drawing.Color]::Transparent)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

# 새 character_2.png (1080x864) 16개 프레임 바운딩 박스
$boxes = @(
    @{r=0;c=0;x1=76;x2=186;y1=19;y2=206},
    @{r=0;c=1;x1=348;x2=458;y1=20;y2=207},
    @{r=0;c=2;x1=620;x2=729;y1=19;y2=207},
    @{r=0;c=3;x1=890;x2=1000;y1=19;y2=207},
    @{r=1;c=0;x1=88;x2=172;y1=227;y2=401},
    @{r=1;c=1;x1=357;x2=443;y1=226;y2=401},
    @{r=1;c=2;x1=627;x2=712;y1=226;y2=400},
    @{r=1;c=3;x1=906;x2=992;y1=227;y2=401},
    @{r=2;c=0;x1=89;x2=177;y1=434;y2=647},
    @{r=2;c=1;x1=358;x2=447;y1=434;y2=647},
    @{r=2;c=2;x1=631;x2=719;y1=434;y2=647},
    @{r=2;c=3;x1=903;x2=995;y1=434;y2=647},
    @{r=3;c=0;x1=83;x2=186;y1=648;y2=822},
    @{r=3;c=1;x1=353;x2=456;y1=648;y2=822},
    @{r=3;c=2;x1=624;x2=728;y1=648;y2=822},
    @{r=3;c=3;x1=894;x2=997;y1=648;y2=822}
)

# 셀 200x300 기준 발바닥 접지(하단 15px 위) + 수평 중앙
# 원본 최대 높이 214px 기준으로 셀 h=300 내에 여유 있게 배치 (스케일 불필요, 그냥 수직 접지만)
foreach ($box in $boxes) {
    $r=$box.r; $c=$box.c
    $char_w=$box.x2-$box.x1+1
    $char_h=$box.y2-$box.y1+1

    $char_bmp = New-Object System.Drawing.Bitmap($char_w,$char_h,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y=$box.y1;$y-le$box.y2;$y++) {
        for ($x=$box.x1;$x-le$box.x2;$x++) {
            $p=$src.GetPixel($x,$y)
            if ($p.A -gt 10) { $char_bmp.SetPixel($x-$box.x1,$y-$box.y1,$p) }
        }
    }

    # 남자캐릭터 높이(245px)에 맞추도록 스케일 적용
    $scale = 245.0 / 188.0   # 기준: 정면 서기 h=188
    $new_w = [int]($char_w * $scale)
    $new_h = [int]($char_h * $scale)

    $dest_x = $c*$w + [int](($w-$new_w)/2)
    $dest_y = ($r+1)*$h - 15 - $new_h

    $g.DrawImage($char_bmp,$dest_x,$dest_y,$new_w,$new_h)
    $char_bmp.Dispose()
}

$g.Dispose()
$out = "c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_2_aligned.png"
$dst.Save($out,[System.Drawing.Imaging.ImageFormat]::Png)
$dst.Dispose(); $src.Dispose()
Write-Host "character_2_aligned.png 재생성 완료!"
