
Describe "Get-Bom" {
    It "Given valid -Path '<Path>', it returns '<Expected>'" -TestCases @(
        @{ Path = "$PSScriptRoot\ascii.txt"; Expected = @() },
        @{ Path = "$PSScriptRoot\bigendianunicode.txt"; Expected = "utf16be" },
        @{ Path = "$PSScriptRoot\unicode.txt"; Expected = "utf16le" },
        @{ Path = "$PSScriptRoot\utf32.txt"; Expected = "utf32le" },
        @{ Path = "$PSScriptRoot\utf8.txt"; Expected = "utf8" }
    ) {
        param ($Path, $Expected)
        &"$PSScriptRoot\..\Get-Bom" $Path | Should -Be $Expected
    }
}
