$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module (Get-Location | Join-Path -ChildPath "src" -AdditionalChildPath "vroide.psm1" ) -Force

InModuleScope -ModuleName vroide -ScriptBlock {
    Describe "Export VRO IDE" {
        BeforeAll {
            ## Code in here
            $vROConnection = "mocked endpoint"
            $TempDir = [System.Guid]::NewGuid().ToString()
            $vroIdeFolder = New-Item -Type Directory -Name $TempDir -path $env:TMPDIR
            $vroActionHeaders = Get-Content -Raw (Get-Location | Join-Path -ChildPath "tests" -AdditionalChildPath "data" | Join-Path -ChildPath  "vroActionHeaders.json") | ConvertFrom-Json
            foreach ($vroActionHeader in $vroActionHeaders){
                $vroActionHeader = $vroActionHeader -as [VroAction]
                $null = New-Item -ItemType Directory -Path $vroActionHeader.modulePath($vroIdeFolder)
            }
        ##code $vroIdeFolder
        }

        BeforeEach {
            foreach ($vroActionHeader in $vroActionHeaders){
                $vroActionHeader = $vroActionHeader -as [VroAction]
                $null = Copy-Item -Path (Get-Location | Join-Path -ChildPath "tests" -AdditionalChildPath "data" | Join-Path -ChildPath "$($vroActionHeader.Name).action") -Destination $vroActionHeader.modulePath($vroIdeFolder)
            }
        }

        AfterEach {
            if (Test-Path $vroActionHeader.filePath($vroIdeFolder,"action")){
                Remove-Item -Path $vroActionHeader.filePath($vroIdeFolder,"action") -Confirm:$false
            }
        }

        Mock Get-vROAction { return (get-content -Raw (Get-Location | Join-Path -ChildPath "tests" -AdditionalChildPath "data" | Join-Path -ChildPath  "vroActionHeaders.json") | ConvertFrom-Json)}
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
            $vroActionHeader = ($vroActionHeaders | Where-Object { $_.id -eq $Id }) -as [VroAction]
            Move-Item -Path $vroActionHeader.filePath($vroIdeFolder,"action") -Destination $path
            $vroActionFile = Get-Item $path
            
            return $vroActionFile
        }
        Mock Import-vROAction {
            param (
                [Parameter(
                    Mandatory = $false
                )]
                [ValidateNotNull()]
                [string[]]$CategoryName,
                [Parameter(
                    Mandatory = $false
                )]
                [string[]]$File,
                [Parameter(
                    Mandatory = $false
                )]
                [bool]$Override        
            )
            return $null
        }

        It "Exports VRO Environment" {
            Export-VroIde -Debug -keepWorkingFolder:$false -vroIdeFolder $vroIdeFolder.FullName
            2 | should be 2
        }
        it "Imports VRO Environment" {
            Import-VroIde -Debug -keepWorkingFolder:$false -vroIdeFolder $vroIdeFolder.FullName
            3 | should be 3
        }
    }
}
#