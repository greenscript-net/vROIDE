$tmpWorkingFolder = New-Item -Path (New-TemporaryFile).DirectoryName -Type Directory -Name "vroide"

Copy-Item ./src/vroide.psd1 $tmpWorkingFolder
Copy-Item ./src/vroide.psm1 $tmpWorkingFolder

Import-Module $tmpWorkingFolder -Force

# Remove-Item $tmpWorkingFolder -Confirm:$false -Force

