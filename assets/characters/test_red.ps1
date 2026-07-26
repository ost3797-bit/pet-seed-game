Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_2_aligned.png")

# character_2_aligned.png는 4열 4행, 1칸당 200x300. Row 2는 y = 600 ~ 899.
Write-Host "Scanning red pixels near bottom of Row 2 in character_2_aligned.png:"
for ($c=0; $c -lt 4; $c++) {
    $start_x = $c * 200; $end_x = $start_x + 199
    # 칸 하단부(y=850~899) 스캔
    for ($y=830; $y -lt 900; $y++) {
        for ($x=$start_x; $x -le $end_x; $x++) {
            $p = $img.GetPixel($x, $y)
            if ($p.A -gt 10 -and $p.R -gt 150 -and $p.G -lt 100 -and $p.B -lt 100) {
                Write-Host "Row 2 Col $c at ($x, $y) : A=$($p.A) R=$($p.R) G=$($p.G) B=$($p.B)"
            }
        }
    }
}
$img.Dispose()
