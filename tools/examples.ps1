Import-Module ./src/vroide.psm1 -Force

# Testing Phase

if (!$vROConnection){
    if (!$cred){
        if (Test-Path ~/defCreds.json){
            $defCreds = Get-Content -Raw -Path ~/defCreds.json | ConvertFrom-Json
            $secpasswd = ConvertTo-SecureString $defCreds.password -AsPlainText -Force
            $cred = New-Object System.Management.Automation.PSCredential ($defCreds.username, $secpasswd)
            $server = $defCreds.server
        }else{
            $cred = Get-Credential -UserName "administrator@vsphere.local"
        }
    }
    if ($server){
        Connect-vROServer -Server $server -Credential $cred -IgnoreCertRequirements -Port 443
    }else{
        Connect-vROServer -Credential $cred -IgnoreCertRequirements -Port 443
    }
}

$vroIdeFolder = Export-VroIde -Debug -keepWorkingFolder:$false -vroIdeFolder /Users/garryhughes/GIT/my-actions/src/

code $vroIdeFolder

Import-VroIde -vroIdeFolder $vroIdeFolder -Debug

Remove-Item $vroIdeFolder -Recurse -Force -Confirm:$false

Disconnect-vROServer -Confirm:$false
