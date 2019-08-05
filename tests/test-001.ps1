$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Get-Location | Join-Path -ChildPath "src" -AdditionalChildPath "vroide.psm1" ) -Force

InModuleScope -ModuleName vroide -ScriptBlock {
    Describe "Export VRO IDE" {
        BeforeAll {
            ## Code in here
            $vROConnection = "mocked endpoint"
            $TempDir = [System.Guid]::NewGuid().ToString()
            $vroIdeFolder = New-Item -Type Directory -Name $TempDir -path $env:TMPDIR
            $moduleFolder = new-item -type Directory -Name "pso.test.gh" -path $vroIdeFolder
            $vroActionHeaders = get-content -Raw (Get-Location | Join-Path -ChildPath "tests" -AdditionalChildPath "data" | Join-Path -ChildPath  "vroActionHeaders.json")
            $vroActionHeaders | ConvertTo-Json | Set-Content ($vroIdeFolder.FullName | Join-Path -ChildPath "vroActionHeaders.json") -Force
            $vroActionFile = copy-item (Get-Location | Join-Path -ChildPath "tests" -AdditionalChildPath "data" | Join-Path -ChildPath  "standard.action") $moduleFolder
            code $vroIdeFolder
        }

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
                [string]$path        
            )
            
            return $vroActionFile
        }
        #Mock Build {} -Verifiable -ParameterFilter {$version -eq 1.2}

        It "Exports VRO Environment" {
            Export-VroIde -vroIdeFolder $vroIdeFolder -Debug | Should be null
            2 | should be 2
        }
    }
}
