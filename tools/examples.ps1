Import-Module ./src/vroide.psm1 -Force

# Testing Phase

$secpasswd = ConvertTo-SecureString "VMware1!" -AsPlainText -Force
$defaultCreds = New-Object System.Management.Automation.PSCredential ("administrator@vsphere.local", $secpasswd)

if (!$vROConnection){
    Write-Host -ForegroundColor Yellow "Trying Default Creds!!!"
    Connect-vROServer -Server "vra.greenscript.net" -Credential $defaultCreds -IgnoreCertRequirements -Port 443
    if (!$vROConnection){
        if (!$cred){$cred = Get-Credential -UserName "administrator@vsphere.local"}
        Connect-vROServer -Server "vra.greenscript.net" -Credential $cred -IgnoreCertRequirements -Port 443
    }
}

$vroIdeFolder = Export-VroIde -Debug -keepWorkingFolder #-vroIdeFolder /Users/garryhughes/GIT/my-actions/src/

code $vroIdeFolder

# Import-VroIde -vroIdeFolder $vroIdeFolder -Debug

Remove-Item $vroIdeFolder -Recurse -Force -Confirm:$false
