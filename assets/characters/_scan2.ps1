Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_2.png")
Write-Host "크기: $($src.Width) x $($src.Height)"
Write-Host "셀 크기(추정): $($src.Width/4.0) x $($src.Height/4.0)"
Write-Host "0,0: $($src.GetPixel(0,0))"
Write-Host "5,5: $($src.GetPixel(5,5))"

$cw = [int]($src.Width/4.0); $ch = [int]($src.Height/4.0)
for ($r=0; $r -lt 4; $r++) {
    for ($c=0; $c -lt 4; $c++) {
        $min_x=10000;$max_x=-1;$min_y=10000;$max_y=-1
        $sx=$c*$cw;$ex=$sx+$cw-1;$sy=$r*$ch;$ey=$sy+$ch-1
        for ($y=$sy;$y-le$ey;$y++) {
            for ($x=$sx;$x-le$ex;$x++) {
                $p=$src.GetPixel($x,$y)
                if ($p.A -gt 10) {
                    if ($x-lt$min_x){$min_x=$x}
                    if ($x-gt$max_x){$max_x=$x}
                    if ($y-lt$min_y){$min_y=$y}
                    if ($y-gt$max_y){$max_y=$y}
                }
            }
        }
        if ($max_x -ge 0) {
            Write-Host "Row ${r} Col ${c}: X=($min_x~$max_x,w=$($max_x-$min_x+1)),Y=($min_y~$max_y,h=$($max_y-$min_y+1))"
        } else { Write-Host "Row ${r} Col ${c}: EMPTY" }
    }
}
$src.Dispose()
