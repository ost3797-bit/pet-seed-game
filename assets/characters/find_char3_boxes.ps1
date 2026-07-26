Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("c:\Users\a\Desktop\godot-engine-4-x-scene-gdscript\outputs\PetSeedGame\assets\characters\character_3.png")

# 행 영역 정의 (Y축 4개)
$row_bounds = @(
    @{min_y=50; max_y=280},
    @{min_y=290; max_y=500},
    @{min_y=510; max_y=720},
    @{min_y=730; max_y=950}
)

for ($r=0; $r -lt 4; $r++) {
    $min_y = $row_bounds[$r].min_y; $max_y = $row_bounds[$r].max_y
    # X축으로 픽셀이 있는 구간(캐릭터) 찾기
    $in_char = $false
    $char_start = 0
    $chars = @()
    for ($x=0; $x -lt $src.Width; $x++) {
        $has_pixel = $false
        for ($y=$min_y; $y -le $max_y; $y += 4) {
            $p = $src.GetPixel($x, $y)
            if ($p.A -gt 10 -and -not ($p.R -gt 235 -and $p.G -gt 235 -and $p.B -gt 235)) {
                $has_pixel = $true; break
            }
        }
        if ($has_pixel -and !$in_char) {
            $in_char = $true; $char_start = $x
        } elseif (!$has_pixel -and $in_char) {
            if (($x - $char_start) -gt 20) { # 20픽셀 이상이어야 의미 있는 캐릭터
                $chars += @{start=$char_start; end=$x-1}
            }
            $in_char = $false
        }
    }
    if ($in_char) { $chars += @{start=$char_start; end=$src.Width-1} }
    Write-Host "Row ${r} found $($chars.Count) characters:"
    for ($i=0; $i -lt $chars.Count; $i++) {
        $c = $chars[$i]
        Write-Host "  Char ${i}: X=$($c.start) to $($c.end) (w=$($c.end - $c.start + 1))"
    }
}
$src.Dispose()
