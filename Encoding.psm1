
<#
.SYNOPSIS
Returns the name of the encoding associated with a file's BOM

.DESCRIPTION
Reads the Byte Order Marking of a file to determine the file's encoding.

.PARAMETER Path
The path to the text file being read

.EXAMPLE
$isUnicode = (Get-Bom ".\MyFile.txt") -like "utf16*"

.NOTES
Reads the minimum number of characters from the file required to classify.  Only supports unicode types.
#>
function Get-Bom {
    Param(
        [Parameter(Mandatory)]
        [ValidateScript( {Test-Path $_ -PathType Leaf} )]
        [string]$Path
    )

    # unicode formats and their byte order mark values
    $boms = @{
        "utf8"    = (239, 187, 191)
        "utf16be" = (254, 255)
        "utf16le" = (255, 254)
        "utf32be" = (0, 0, 254, 255)
        "utf32le" = (255, 254, 0, 0)
    }

    # read the minimum required bytes into $buffer
    try {
        $bufferSize = ($boms.Keys | % {$boms[$_].Count} | Measure -Maximum).Maximum
        $fileStream = [IO.File]::Open((Resolve-Path $Path), [IO.FileMode]::Open)
        $binaryReader = [IO.BinaryReader]::new($fileStream)
        $buffer = [byte[]]::new($bufferSize)
        $binaryReader.Read($buffer, 0, $bufferSize) | Out-Null
    } catch {
        throw $_
    } finally {
        $binaryReader.Close()
    }

    # compare BOMs to $buffer
    $matchedBoms = $boms.Keys | ? {
        $bomBytes = $boms[$_]
        $diffs = 1..($bomBytes.Count - 1) | ? {$buffer[$_] -ne $bomBytes[$_]}
        return -not $diffs
    }

    # return the longest (most specific) matching BOM
    return $matchedBoms | Sort {$boms[$_].Count} -Descending | Select -First 1
}




<#
.SYNOPSIS
Returns a boolean indicating whether the file can be parsed as the specified encoding.

.DESCRIPTION
Reads the file and ensures each character conforms to the specified encoding

.PARAMETER Path
The path to the file to test

.PARAMETER Encoding
The name of the encoding to validate

.EXAMPLE
if (-not (Test-Parseable ".\myfile.txt", "ascii")) { throw "Invalid Encoding" }

.NOTES
General notes
#>
function Test-Parseable {
    Param(
        [Parameter(Mandatory)]
        [ValidateScript( {Test-Path $_ -PathType Leaf} )]
        [string]$Path,
        [Parameter(Mandatory)]
        [ValidateSet("ascii", "utf8", "utf16be", "utf16le", "utf32be", "utf32le")]
        [string]$Encoding
    )

    $Path = Resolve-Path $Path

    # map encoding identifier to .NET Encoding subclass
    $encodings = @{
        "utf8"    = [Text.UTF8Encoding]::new($true, $true)
        "utf16be" = [Text.UnicodeEncoding]::new($true, $true, $true)
        "utf16le" = [Text.UnicodeEncoding]::new($false, $true, $true)
        "utf32be" = [Text.UTF32Encoding]::new($true, $true, $true)
        "utf32le" = [Text.UTF32Encoding]::new($false, $true, $true)
    }

    if ($Encoding -eq "ascii") {
        # parse the file manually, testing if values are in range
        try {
            $fileStream = [IO.File]::Open($Path, [IO.FileMode]::Open)
            $binaryReader = [IO.BinaryReader]::new($fileStream)
            while ($binaryReader.PeekChar() -ne -1) {
                if ($binaryReader.ReadByte() -gt 127) {
                    return $false
                }
            }
            return $true
        } catch {
            throw $_
        } finally {
            $binaryReader.Close()
        }
    } else {
        # parse the file using .NET parser, throwing an error on invalid chars
        try {
            $streamReader = [IO.StreamReader]::new($Path, $encodings[$Encoding])
            $streamReader.ReadToEnd() | Out-Null
            return $true
        } catch {
            return $false
        } finally {
            $streamReader.Close()
        }
    }
}



<#
.SYNOPSIS
Tests that the file can be read without erroring using the specified encoding.

.DESCRIPTION
Tests that the BOM, Encoding, and characters do not conflict.  If no encoding is specified, infers the encoding from the BOM.  If no BOM is in the file and no Encoding is specified, assumes "ascii" encoding.

.PARAMETER Path
The path of the file being tested

.PARAMETER Encoding
Forces interpretation of the file as the specified encoding instead of only assuming the encoding from BOM.

.EXAMPLE
Test-Encoding ".\myFile.txt" -Encoding "utf8"
#>
function Test-Encoding {
    Param(
        [Parameter(Mandatory)]
        [ValidateScript( {Test-Path $_ -PathType Leaf} )]
        [string]$Path,
        [ValidateSet("ascii", "utf8", "utf16be", "utf16le", "utf32be", "utf32le")]
        [string]$Encoding
    )

    $bom = Get-Bom $Path
    if ($bom) {
        if ($Encoding) {
            return $bom -eq $Encoding -and (Test-Parseable $Path $Encoding)
        } else {
            return Test-Parseable $Path $bom
        }
    } else {
        if ($Encoding) {
            return $Encoding -in ("ascii", "utf8") -and (Test-Parseable $Path $Encoding)
        } else {
            return Test-Parseable $Path "ascii"
        }
    }
}

