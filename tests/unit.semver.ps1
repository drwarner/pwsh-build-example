using module ..\src\release-packaging\semver.psm1
Import-module Pester

$ValidVersions = @(
    "0.11.12",
    "1.2.3",
    "11.23.43-alpha",
    "9.87.2-alpha1+21092"
);

$InvalidVersions = @(
    "1.02",
    "1",
    "1+12-31283"
)

Describe "StringToSemver" {
    It "Parses a valid versions" {
        {
            foreach($v in $ValidVersions) {
                Write-Host "testing $v"            
                [Semver]::new("$v")
            }                
        } | should not throw
    } 

    It "Parses invalid versions" {
        foreach($v in $InvalidVersions) {
            Write-Host "testing $v"            
            try {
                [Semver]::new("$v")
            } catch {
                $errored = $true
            }
            $errored | Should be $true
        }  
    }
}