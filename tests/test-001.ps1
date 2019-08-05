$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Get-Location | Join-Path -ChildPath "src" -AdditionalChildPath "vroide.psm1" ) -Force

Describe "Export VRO IDE" {
    Mock Get-vROAction {return $vroActionHeaders}
    Mock Export-vROAction {
        param (
            [Parameter(
                Mandatory = $false
            )]
            [ValidateNotNull()]
            [string[]]$Id,
            [Parameter(
                Mandatory = $false
            )]
            [string]$Path        
        )
        
        return null
    }
    #Mock Build {} -Verifiable -ParameterFilter {$version -eq 1.2}
    BeforeAll {
        ## Code in here
        $vROConnection = "mocked endpoint"
        $TempDir = [System.Guid]::NewGuid().ToString()
        $vroIdeFolder = New-Item -Type Directory -Name $TempDir -path $env:TMPDIR
        $vroActionHeaders = get-content -Raw (Get-Location | Join-Path -ChildPath "tests" -AdditionalChildPath "data" | Join-Path -ChildPath  "vroActionHeaders.json")
        $vroActionHeaders | ConvertTo-Json | Set-Content ($vroIdeFolder.FullName | Join-Path -ChildPath "vroActionHeaders.json") -Force
        code $vroIdeFolder
    }

    It "Exports VRO Environment" {
        Export-VroIde -vroIdeFolder $vroIdeFolder -Debug | Should be null
        2 | should be 2
    }
}
