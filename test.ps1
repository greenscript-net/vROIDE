Write-Host "Hello World from $Env:AGENT_NAME."
Write-Host "My ID is $Env:AGENT_ID."
Write-Host "AGENT_WORKFOLDER contents:"
Get-ChildItem $Env:AGENT_WORKFOLDER
Write-Host "AGENT_BUILDDIRECTORY contents:"
Get-ChildItem $Env:AGENT_BUILDDIRECTORY
Write-Host "BUILD_SOURCESDIRECTORY contents:"
Get-ChildItem $Env:BUILD_SOURCESDIRECTORY
Write-Host "Over and out."

"current location: $(Get-Location)"
"script root: $PSScriptRoot"
"retrieve available modules"
$modules = Get-Module -list
if ($modules.Name -notcontains 'pester') {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}
if ($modules.Name -notcontains 'PowervRO') {
    Install-Module -Name PowervRO -Force -SkipPublisherCheck
}
Invoke-Pester -Script ( Get-Location | Join-Path -ChildPath "tests" ) -OutputFile ( Get-Location | Join-Path -ChildPath "TEST-Pester.XML" ) -OutputFormat 'NUnitXML'