$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Describe -Tags "Export VRO IDE" {
    Mock Get-VroAction {return $vroActionHeaders}
    Mock Export-VroAction {return null}
    #Mock Build {} -Verifiable -ParameterFilter {$version -eq 1.2}
    BeforeAll {
        ## Code in here
        Import-Module ./src/vroide.psm1 -Force
        $vROConnection = "mocked endpoint"
        $TempDir = [System.Guid]::NewGuid().ToString()
        $vroIdeFolder = New-Item -Type Directory -Name $TempDir -path $env:TMPDIR
        $vroIdeFolder
        $vroActionHeaders = get-content -Raw (Get-Location | Join-Path -ChildPath test -AdditionalChildPath "data" | Join-Path -ChildPath  "vroActionHeaders.json")
        $vroActionHeaders | ConvertTo-Json | set-content ($vroIdeFolder | Join-Path -ChildPath "vroActionHeaders.json")
    }

    It "Exports VRO Environment" {
        Export-VroIde -vroIdeFolder $vroIdeFolder -Debug | Should be 2
    }
}
