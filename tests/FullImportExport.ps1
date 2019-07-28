if (Get-Module VroIde){
    Remove-Module VroIde
}
Import-Module ./Modules/VroDevTools/VroIde.psm1

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

$vroActionHeaders = Get-vROAction | Where-Object { $_.FQN -notlike "com.vmware*" }

# create temporary folder
if (!$workingFolder){
    $workingFolder = CreateTemporaryFolder
}

# Creating Folders

foreach ($vroActionHeader in $vroActionHeaders){
    Write-Host -ForegroundColor Green "Creating Folder : $($vroActionHeader.FQN)"
    $moduleFolder = "$($workingFolder.FullName)/$($vroActionHeader.FQN.split("/")[0])"
    $actionFolder = "$moduleFolder/$($vroActionHeader.FQN.split("/")[1])"
    if (!(test-path $moduleFolder)){$null = New-Item -ItemType Directory -Path $moduleFolder}
    if (!(test-path $actionFolder)){$null = New-Item -ItemType Directory -Path $actionFolder}
}

# Downloading Actions

foreach ($vroActionHeader in $vroActionHeaders){
    Write-Host -ForegroundColor Green "Downloading Action : $($vroActionHeader.FQN)"
    $moduleFolder = "$($workingFolder.FullName)/$($vroActionHeader.FQN.split("/")[0])"
    $actionFolder = "$moduleFolder/$($vroActionHeader.FQN.split("/")[1])"
    $null = Export-vROAction -Id $vroActionHeader.Id -Path $actionFolder
}

# Expanding Actions

foreach ($vroActionHeader in $vroActionHeaders){
    Write-Host -ForegroundColor Green "Expanding Action : $($vroActionHeader.FQN)"
    $moduleFolder = "$($workingFolder.FullName)/$($vroActionHeader.FQN.split("/")[0])"
    $actionFolder = "$moduleFolder/$($vroActionHeader.FQN.split("/")[1])"
    Expand-Archive -Path "$actionFolder/$($vroActionHeader.Name).action" -DestinationPath $actionFolder -Force
}

# Renaming Downloads

foreach ($vroActionHeader in $vroActionHeaders){
    Write-Host -ForegroundColor Green "Expanding Action : $($vroActionHeader.FQN)"
    $moduleFolder = "$($workingFolder.FullName)/$($vroActionHeader.FQN.split("/")[0])"
    $actionFolder = "$moduleFolder/$($vroActionHeader.FQN.split("/")[1])"
    Rename-Item -Path "$actionFolder/$($vroActionHeader.Name).action" -NewName "original.action" -Confirm:$false
}

# Import XML convert to jsdoc convert save
foreach ($vroActionHeader in $vroActionHeaders){
    Write-Host -ForegroundColor Green "Convert from XML to JS and Save for Action : $($vroActionHeader.FQN)"
    $moduleFolder = "$($workingFolder.FullName)/$($vroActionHeader.FQN.split("/")[0])"
    $actionFolder = "$moduleFolder/$($vroActionHeader.FQN.split("/")[1])"
    $vroActionXml = [xml](get-content "$actionFolder/action-content")
    $vroAction = ConvertFrom-VroActionXml -InputObject $vroActionXml
    $vroActionJs = ConvertTo-VroActionJs -InputObject $vroAction
    $vroActionJs | set-content "$actionFolder/$($vroAction.Id).js"
}

# Import jsodc convert to xml convert save
foreach ($vroActionHeader in $vroActionHeaders){
    Write-Host -ForegroundColor Green "Convert from XML to JS and Save for Action : $($vroActionHeader.FQN)"
    $moduleFolder = "$($workingFolder.FullName)/$($vroActionHeader.FQN.split("/")[0])"
    $actionFolder = "$moduleFolder/$($vroActionHeader.FQN.split("/")[1])"
    $vroActionJs = Get-Content "$actionFolder/$($vroActionHeader.Id).js"
    $vroAction = ConvertFrom-VroActionJs -InputObject $vroActionJs -Id $vroActionHeader.Id
    $vroActionXml = ConvertTo-VroActionXml -inputObject $vroAction
    $vroActionXml.Save("$actionFolder/$($vroActionHeader.Name).xml")
}

# Import jsodc convert to xml convert save
foreach ($vroActionHeader in $vroActionHeaders){
    Write-Host -ForegroundColor Green "Convert from XML to JS and Save for Action : $($vroActionHeader.FQN)"
    $moduleFolder = "$($workingFolder.FullName)/$($vroActionHeader.FQN.split("/")[0])"
    $actionFolder = "$moduleFolder/$($vroActionHeader.FQN.split("/")[1])"
    $vroActionJs = Get-Content "$actionFolder/$($vroActionHeader.Id).js"
    $vroAction = ConvertFrom-VroActionJs -InputObject $vroActionJs -Id $vroActionHeader.Id
    $vroActionXml = ConvertTo-VroActionXml -inputObject $vroAction

    Export-VroActionFile -InputObject $vroActionXml -exportFolder $actionFolder
}

# Compare

foreach ($vroActionHeader in $vroActionHeaders){
    $moduleFolder = "$($workingFolder.FullName)/$($vroActionHeader.FQN.split("/")[0])"
    $actionFolder = "$moduleFolder/$($vroActionHeader.FQN.split("/")[1])"

    $compareResult = Compare-VroActionContents -OriginalVroActionFile $actionFolder/original.action -UpdatedVroActionFile "$actionFolder/$($vroActionHeader.Name).action" #-Debug
    if ($compareResult){
        Write-Host -ForegroundColor Green "Comparing $($vroActionHeader.Name) : would not be updated - file hash identical"
    }else{
        Write-Host -ForegroundColor Red "Comparing $($vroActionHeader.Name) : would be updated - file hash not identical"
    }
}

Disconnect-vROServer -Confirm:$false

remove-item $workingFolder -Recurse -Force -Confirm:$false
$workingFolder = $null