Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_3.png")

$w = 200; $h = 300
$dst = New-Object System.Drawing.Bitmap(($w * 4), ($h * 4), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($dst)
$g.Clear([System.Drawing.Color]::Transparent)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

# 새 character_3.png (1080x720) 의 16개 프레임 정밀 바운딩 박스
$boxes = @(
    @{r=0; c=0; x1=159; x2=255; y1=16; y2=173},
    @{r=0; c=1; x1=411; x2=503; y1=18; y2=173},
    @{r=0; c=2; x1=625; x2=718; y1=16; y2=173},
    @{r=0; c=3; x1=816; x2=908; y1=18; y2=173},
    @{r=1; c=0; x1=159; x2=244; y1=194; y2=350},
    @{r=1; c=1; x1=407; x2=491; y1=194; y2=350},
    @{r=1; c=2; x1=624; x2=709; y1=194; y2=350},
    @{r=1; c=3; x1=824; x2=909; y1=194; y2=350},
    @{r=2; c=0; x1=161; x2=247; y1=373; y2=525},
    @{r=2; c=1; x1=402; x2=488; y1=373; y2=526},
    @{r=2; c=2; x1=619; x2=706; y1=373; y2=524},
    @{r=2; c=3; x1=818; x2=904; y1=373; y2=520},
    @{r=3; c=0; x1=165; x2=253; y1=548; y2=703},
    @{r=3; c=1; x1=402; x2=489; y1=548; y2=703},
    @{r=3; c=2; x1=627; x2=714; y1=548; y2=702},
    @{r=3; c=3; x1=822; x2=909; y1=548; y2=703}
)

# 여자 캐릭터(245px)에 맞추도록 스케일 계산
# 원본 캐릭터 평균 높이 약 156px -> 245/156 = 1.571 배 확대
$scale = 245.0 / 157.0

foreach ($box in $boxes) {
    $r = $box.r; $c = $box.c
    $char_w = $box.x2 - $box.x1 + 1
    $char_h = $box.y2 - $box.y1 + 1

    # 흰색/투명 배경 제거 후 개별 캐릭터 비트맵 추출
    $char_bmp = New-Object System.Drawing.Bitmap($char_w, $char_h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y=$box.y1; $y -le $box.y2; $y++) {
        for ($x=$box.x1; $x -le $box.x2; $x++) {
            $p = $src.GetPixel($x, $y)
            if ($p.A -gt 30 -and -not ($p.R -gt 230 -and $p.G -gt 230 -and $p.B -gt 230)) {
                $char_bmp.SetPixel($x - $box.x1, $y - $box.y1, $p)
            }
        }
    }

    # 여자 캐릭터와 동일한 크기로 확대
    $new_w = [int]($char_w * $scale)
    $new_h = [int]($char_h * $scale)

    # 수평 중앙 정렬 + 발바닥 하단 15px 위 접지
    $dest_x = $c * $w + [int](($w - $new_w) / 2)
    $dest_y = ($r + 1) * $h - 15 - $new_h

    $g.DrawImage($char_bmp, $dest_x, $dest_y, $new_w, $new_h)
    $char_bmp.Dispose()
}

$g.Dispose()
$outPath = "c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_3_aligned.png"
$dst.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$dst.Dispose()
$src.Dispose()
Write-Host "character_3_aligned.png 재생성 완료!"
