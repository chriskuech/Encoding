
Import-Module "$PSScriptRoot\..\Encoding" -Force


Describe "Test-Encoding" {
    It "Given valid -Path '<Path>' and -Encoding '<Encoding>', it returns '<Expected>'" -TestCases @(
        @{ Path = "$PSScriptRoot\ascii.txt"; Encoding = "ascii"; Expected = $true },
        @{ Path = "$PSScriptRoot\bigendianunicode.txt"; Encoding = "utf16be"; Expected = $true },
        @{ Path = "$PSScriptRoot\unicode.txt"; Encoding = "utf16le"; Expected = $true },
        @{ Path = "$PSScriptRoot\utf32.txt"; Encoding = "utf32le"; Expected = $true },
        @{ Path = "$PSScriptRoot\utf8.txt"; Encoding = "utf8"; Expected = $true },
        @{ Path = "$PSScriptRoot\ascii.txt"; Expected = $true },
        @{ Path = "$PSScriptRoot\unicode.txt"; Expected = $true },
        @{ Path = "$PSScriptRoot\utf32.txt"; Encoding = "utf8"; Expected = $false },
        @{ Path = "$PSScriptRoot\bad.txt"; Encoding = "ascii"; Expected = $false }
    ) {
        Param($Path, $Encoding, $Expected)
        if ($Encoding) {
            Test-Encoding -Path $Path -Encoding $Encoding | Should -Be $Expected
        } else {
            Test-Encoding -Path $Path                     | Should -Be $Expected            
        }
    }
}

