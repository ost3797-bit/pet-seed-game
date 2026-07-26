Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_3.png")
# X축 10픽셀 단위로 픽셀 개수 세기
for ($x=0; $x -lt $src.Width; $x += 30) {
    $cnt = 0
    for ($y=0; $y -lt $src.Height; $y += 10) {
        $p = $src.GetPixel($x, $y)
        if ($p.A -gt 10 -and -not ($p.R -gt 235 -and $p.G -gt 235 -and $p.B -gt 235)) {
            $cnt++
        }
    }
    if ($cnt -gt 0) { Write-Host "X=${x}: count=${cnt}" }
}
$src.Dispose()
