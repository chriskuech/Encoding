Param(
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$Path
)

$boms = @{
    "utf8"    = (239, 187, 191)
    "utf16be" = (254, 255)
    "utf16le" = (255, 254)
    "utf32be" = (0, 0, 254, 255)
    "utf32le" = (255, 254, 0, 0)
}

# read the minimum required bytes into $buffer
$bufferSize = ($boms.Keys | % {$boms[$_].Count} | Measure -Maximum).Maximum
$fileStream = [IO.File]::Open((Resolve-Path $Path), [IO.FileMode]::Open)
$binaryReader = [IO.BinaryReader]::new($fileStream)
$buffer = [byte[]]::new($bufferSize)
$binaryReader.Read($buffer, 0, $bufferSize) | Out-Null
$binaryReader.Close()

# compare BOMs to $buffer
$matchedBoms = $boms.Keys | ? {
    $bomBytes = $boms[$_]
    $diffs = 1..($bomBytes.Count - 1) | ? {$buffer[$_] -ne $bomBytes[$_]}
    return -not $diffs
}

# return the longest (most specific) matching BOM
return $matchedBoms | Sort {$boms[$_].Count} -Descending | Select -First 1
