$ErrorActionPreference = "Stop"
$hdc = 'D:\HUAWEI\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'
$shotDir = 'D:\FogHarbor\docs\screenshots'
$layoutFile = Join-Path $env:TEMP 'fog_play_layout.json'

function Get-Layout {
    & $hdc shell uitest dumpLayout -p /data/local/tmp/layout.json | Out-Null
    & $hdc file recv /data/local/tmp/layout.json $layoutFile | Out-Null
    return (Get-Content $layoutFile -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Tap($text, $index = 0) {
    $layout = Get-Layout
    $script:matches = @()
    function Collect($n, $t) {
        if ($null -ne $n.attributes.text -and $n.attributes.text -eq $t) { $script:matches += $n }
        foreach ($c in $n.children) { Collect $c $t }
    }
    Collect $layout $text
    if ($script:matches.Count -eq 0) { Write-Output "NOT_FOUND: $text"; return $false }
    $node = $script:matches[[Math]::Min($index, $script:matches.Count - 1)]
    if ($node.attributes.bounds -match '\[(\d+),(\d+)\]\[(\d+),(\d+)\]') {
        $x = [int](([int]$matches[1] + [int]$matches[3]) / 2)
        $y = [int](([int]$matches[2] + [int]$matches[4]) / 2)
        & $hdc shell uitest uiInput click $x $y | Out-Null
        Write-Output "TAP $text -> $x,$y"
        return $true
    }
    return $false
}

function SkipTyping {
    & $hdc shell uitest uiInput click 630 900 | Out-Null
}

function Shot($name) {
    $remote = "/data/local/tmp/$name.jpeg"
    & $hdc shell "snapshot_display -f $remote" | Out-Null
    & $hdc file recv $remote (Join-Path $shotDir "raw-$name.jpeg") | Out-Null
    Write-Output "SHOT $name"
}

function Choose($text) {
    SkipTyping
    Start-Sleep -Milliseconds 700
    Tap $text | Out-Null
    Start-Sleep -Milliseconds 900
    SkipTyping
    Start-Sleep -Milliseconds 500
}

& $hdc shell aa force-stop com.goodjinkela.fogharbor | Out-Null
& $hdc uninstall com.goodjinkela.fogharbor | Out-Null
Start-Sleep -Seconds 2
& $hdc install 'D:\FogHarbor\entry\build\default\outputs\default\entry-default-unsigned.hap' | Out-Null
Start-Sleep -Seconds 2
& $hdc shell aa start -a EntryAbility -b com.goodjinkela.fogharbor | Out-Null
Start-Sleep -Seconds 5

Shot '01-home'
if (-not (Tap '开始调查')) { Tap '继续调查' 1 | Out-Null }
Start-Sleep -Seconds 2
SkipTyping
Start-Sleep -Milliseconds 800
& $hdc shell uitest uiInput swipe 630 2150 630 1500 400 | Out-Null
Start-Sleep -Milliseconds 600
Shot '02-story'

Choose '当场拆开信封'
& $hdc shell uitest uiInput swipe 630 2150 630 1550 400 | Out-Null
Start-Sleep -Milliseconds 600
Shot '03-locked'

Choose '递一支烟，先聊码头上的旧事'

Tap '存档'
Start-Sleep -Seconds 2
Tap '保存到此' 0 | Out-Null
Start-Sleep -Seconds 2
Shot '05-saves'
Tap '‹'
Start-Sleep -Seconds 2

Choose '举起相机，拍下箱号和封条'
Choose '调出三年前的微缩胶片，一版一版看'
Choose '把这几天查到的一切都告诉他'
Choose '请乐队再奏一支她当年在船上唱过的曲子'
Choose '先回报馆，把稿子发出去'
Choose '闪身躲进集装箱的夹缝'
Choose '把账本交给他'
Choose '把账本扔给顾长风，自己去引开追兵'
Start-Sleep -Seconds 2
Shot '06-ending'

Tap '回顾'
Start-Sleep -Seconds 2
Shot '07-history'
Tap '‹'
Start-Sleep -Seconds 2
Tap '返回首页'
Start-Sleep -Seconds 2
Shot '08-home-after'
Tap '结局图鉴'
Start-Sleep -Seconds 2
Shot '09-gallery'

Write-Output "DONE"
