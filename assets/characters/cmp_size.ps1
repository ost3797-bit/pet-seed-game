Add-Type -AssemblyName System.Drawing
foreach ($f in @("character_2_aligned.png", "character_0_aligned.png")) {
    $src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\$f")
    $min_x=1000; $max_x=-1000; $min_y=1000; $max_y=-1000
    for ($y=0; $y -lt 300; $y++) {
        for ($x=0; $x -lt 200; $x++) {
            if ($src.GetPixel($x, $y).A -gt 10) {
                if ($x -lt $min_x) { $min_x = $x }
                if ($x -gt $max_x) { $max_x = $x }
                if ($y -lt $min_y) { $min_y = $y }
                if ($y -gt $max_y) { $max_y = $y }
            }
        }
    }
    Write-Host "$f => w=$($max_x-$min_x+1), h=$($max_y-$min_y+1) (min_y=$min_y, max_y=$max_y)"
    $src.Dispose()
}
