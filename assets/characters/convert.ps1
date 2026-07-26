Add-Type -AssemblyName System.Drawing

function Convert-CharacterSheet($inPath, $outPath) {
    Write-Host "Processing $inPath ..."
    $src = [System.Drawing.Bitmap]::FromFile($inPath)
    
    $w = 140; $h = 180
    $dst = New-Object System.Drawing.Bitmap(($w * 4), ($h * 4), [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($dst)
    $g.Clear([System.Drawing.Color]::Transparent)
    
    $x_centers = @(451, 720, 1000, 1288)
    $y_centers = @(167, 388, 603, 821)
    
    for ($r=0; $r -lt 4; $r++) {
        for ($c=0; $c -lt 4; $c++) {
            $cx = $x_centers[$c]
            $cy = $y_centers[$r]
            
            for ($iy=0; $iy -lt $h; $iy++) {
                for ($ix=0; $ix -lt $w; $ix++) {
                    $sx = $cx - 70 + $ix
                    $sy = $cy - 90 + $iy
                    
                    if ($sx -ge 0 -and $sx -lt $src.Width -and $sy -ge 0 -and $sy -lt $src.Height) {
                        $p = $src.GetPixel($sx, $sy)
                        if (!($p.R -ge 235 -and $p.G -ge 230 -and $p.B -ge 215)) {
                            $dst.SetPixel(($c * $w + $ix), ($r * $h + $iy), $p)
                        }
                    }
                }
            }
        }
    }
    $g.Dispose()
    $tmpPath = $outPath + ".tmp.png"
    $dst.Save($tmpPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $dst.Dispose()
    $src.Dispose()
    
    if (Test-Path $outPath) { Remove-Item $outPath -Force }
    Rename-Item $tmpPath (Split-Path $outPath -Leaf) -Force
    Write-Host "Saved to $outPath successfully!"
}

$dir = "c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters"
Convert-CharacterSheet "$dir\character_0_orig.png" "$dir\character_0.png"
Convert-CharacterSheet "$dir\character_1_orig.png" "$dir\character_1.png"
