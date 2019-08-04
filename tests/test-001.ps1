$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Describe "Export VRO IDE" {
    Mock Get-VroAction {return $vroActionHeaders}
    Mock Export-VroAction {return null}
    #Mock Build {} -Verifiable -ParameterFilter {$version -eq 1.2}
    BeforeAll {
        ## Code in here
        Import-Module (Get-Location | Join-Path -ChildPath "src" -AdditionalChildPath "vroide.psm1" ) -Force
        $vROConnection = "mocked endpoint"
        $TempDir = [System.Guid]::NewGuid().ToString()
        $vroIdeFolder = New-Item -Type Directory -Name $TempDir -path $env:TMPDIR
        $vroIdeFolder
        $vroActionHeaders = get-content -Raw (Get-Location | Join-Path -ChildPath "tests" -AdditionalChildPath "data" | Join-Path -ChildPath  "vroActionHeaders.json")
        $vroActionHeaders | ConvertTo-Json | set-content ($vroIdeFolder | Join-Path -ChildPath "vroActionHeaders.json")
    }

    It "Exports VRO Environment" {
        Export-VroIde -vroIdeFolder $vroIdeFolder -Debug | Should be null
    }
}
