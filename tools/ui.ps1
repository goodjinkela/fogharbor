param(
    [Parameter(Mandatory = $true)][string]$Action,
    [string]$Value = "",
    [int]$Index = 0
)

$ErrorActionPreference = "Stop"
$hdc = 'D:\HUAWEI\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe'
$shotDir = 'D:\FogHarbor\docs\screenshots'
$layoutFile = Join-Path $env:TEMP 'fog_layout.json'

function Get-Layout {
    & $hdc shell uitest dumpLayout -p /data/local/tmp/layout.json | Out-Null
    & $hdc file recv /data/local/tmp/layout.json $layoutFile | Out-Null
    return (Get-Content $layoutFile -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Find-Node($node, $text) {
    $attr = $node.attributes
    if ($null -ne $attr -and $null -ne $attr.text -and $attr.text -eq $text) {
        return $node
    }
    foreach ($child in $node.children) {
        $hit = Find-Node $child $text
        if ($null -ne $hit) { return $hit }
    }
    return $null
}

function Find-Contains($node, $text) {
    $attr = $node.attributes
    if ($null -ne $attr -and $null -ne $attr.text -and $attr.text -like "*$text*") {
        return $node
    }
    foreach ($child in $node.children) {
        $hit = Find-Contains $child $text
        if ($null -ne $hit) { return $hit }
    }
    return $null
}

function Get-Center($bounds) {
    if ($bounds -match '\[(\d+),(\d+)\]\[(\d+),(\d+)\]') {
        $x = ([int]$matches[1] + [int]$matches[3]) / 2
        $y = ([int]$matches[2] + [int]$matches[4]) / 2
        return @([int]$x, [int]$y)
    }
    return $null
}

switch ($Action) {
    "tap" {
        $layout = Get-Layout
        $script:matches = @()
        function Collect($n, $text) {
            if ($null -ne $n.attributes.text -and $n.attributes.text -eq $text) {
                $script:matches += $n
            }
            foreach ($c in $n.children) { Collect $c $text }
        }
        Collect $layout $Value
        if ($script:matches.Count -eq 0) { Write-Output "NOT_FOUND: $Value"; exit 2 }
        $node = $script:matches[[Math]::Min($Index, $script:matches.Count - 1)]
        $c = Get-Center $node.attributes.bounds
        & $hdc shell uitest uiInput click $c[0] $c[1] | Out-Null
        Write-Output "TAPPED: $Value [$Index] at $($c[0]),$($c[1])"
    }
    "shot" {
        $remote = "/data/local/tmp/$Value.jpeg"
        $local = Join-Path $shotDir "raw-$Value.jpeg"
        & $hdc shell "snapshot_display -f $remote" | Out-Null
        & $hdc file recv $remote $local | Out-Null
        Write-Output "SHOT: $local"
    }
    "skip" {
        & $hdc shell uitest uiInput click 630 900 | Out-Null
        Write-Output "SKIPPED"
    }
    "texts" {
        $layout = Get-Layout
        $script:lines = @()
        function Walk($n) {
            if ($null -ne $n.attributes.text -and $n.attributes.text -ne "") {
                $script:lines += ("{0} | {1}" -f $n.attributes.text, $n.attributes.bounds)
            }
            foreach ($c in $n.children) { Walk $c }
        }
        Walk $layout
        $script:lines | ForEach-Object { Write-Output $_ }
    }
    "restart" {
        & $hdc shell aa force-stop com.goodjinkela.fogharbor | Out-Null
        & $hdc shell aa start -a EntryAbility -b com.goodjinkela.fogharbor | Out-Null
        Write-Output "RESTARTED"
    }
}
