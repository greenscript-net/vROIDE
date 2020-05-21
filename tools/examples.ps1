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
        Connect-vROServer -Server $server -Credential $cred -IgnoreCertRequirements -Port $defCreds.port -SslProtocol Ssl3
    }else{
        Connect-vROServer -Credential $cred -IgnoreCertRequirements -Port 443 -SslProtocol Ssl3
    }
}

if ($vroIdeFolder){
    Export-VroIde -Debug -keepWorkingFolder:$false -vroIdeFolder $vroIdeFolder
}else{
    $vroIdeFolder = Export-VroIde -Debug -keepWorkingFolder:$false #-vroIdeFolder /Users/garryhughes/GIT/my-actions/
}

code $vroIdeFolder

Import-VroIde -vroIdeFolder $vroIdeFolder #-Debug
Export-VroIde -Debug -keepWorkingFolder:$false -vroIdeFolder $vroIdeFolder
code $vroIdeFolder

Remove-Item $vroIdeFolder -Recurse -Force -Confirm:$false

Disconnect-vROServer -Confirm:$false
