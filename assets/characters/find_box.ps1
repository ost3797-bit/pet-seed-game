Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_0.png")

# x=200 부근에서 수직으로 내려오며 테두리나 배경이 아닌 선 위치 찾기
for ($y=0; $y -lt 300; $y+=5) {
    $c = $bmp.GetPixel(500, $y)
    if ($c.R -lt 200 -or $c.G -lt 200 -or $c.B -lt 200) {
        Write-Host "Top edge candidate at y=$y : R=$($c.R) G=$($c.G) B=$($c.B)"
    }
}
# 수평으로 좌우 테두리 찾기 (y=200에서 x 스캔)
for ($x=0; $x -lt 500; $x+=5) {
    $c = $bmp.GetPixel($x, 200)
    if ($c.R -lt 200 -or $c.G -lt 200 -or $c.B -lt 200) {
        Write-Host "Left edge candidate at x=$x : R=$($c.R) G=$($c.G) B=$($c.B)"
    }
}
$bmp.Dispose()
