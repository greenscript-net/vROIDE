Class VroActionInput {
    [string] $name
    [string] $description
    [string] $type
}

Class VroAction {
    [guid] $Id
    [string] $Name
    [string] $Description
    [string] $FQN
    [String] $Version
    [VroActionInput[]] $InputParameters
    [string] $OutputType
    [string] $Href
    [System.Object[]] $Relations
    [string] $Script
    [string] $Module
    [string] $TagsGlobal
    [string] $TagsUser
    [string] $AllowedOperations
    [string] modulePath ($basePath) {
        return (Join-Path -Path $basePath -ChildPath $this.FQN.Split("/")[0])
    }
    [string] filePath ($basePath, [string]$fileExtension) {
        return (Join-Path -Path $basePath -ChildPath $this.FQN.Split("/")[0] -AdditionalChildPath "$($this.Name).$fileExtension")
    }
}

function NewGuid {
    return "{$([guid]::NewGuid().Guid)}".ToUpper()
}

function CreateTemporaryFolder {
    $TempDir = [System.Guid]::NewGuid().ToString()
    $TempDirObj = New-Item -Type Directory -Name $TempDir -path $env:TMPDIR
    return $TempDirObj    
}

function ConvertFrom-VroActionXml {
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNull()]
        [xml]$InputObject
    )

    $xml = $InputObject

    # Init

    $vroAction = [VroAction]::new();

    # process xml

    $vroAction.Name = $xml.'dunes-script-module'.name
    $vroAction.Description = $xml.'dunes-script-module'.description.'#cdata-section'
    $vroAction.OutputType = $xml.'dunes-script-module'.'result-type'
    $vroAction.Script = $xml.'dunes-script-module'.script.'#cdata-section'
    $vroAction.Version = $xml.'dunes-script-module'.version

    if ($xml.'dunes-script-module'.'allowed-operations'){
        $vroAction.AllowedOperations = $xml.'dunes-script-module'.'allowed-operations'
    }

    if ($xml.'dunes-script-module'.'id' -as [guid]){
        $vroAction.Id = $xml.'dunes-script-module'.'id'
    }else{
        $vroAction.Id = $xml.'dunes-script-module'.'id'.substring(0,4) + $xml.'dunes-script-module'.'id'.substring(32,4) + $xml.'dunes-script-module'.'id'.substring(41,24)
    }

    if ($xml.'dunes-script-module'.param) {
        $inputs = @()
        foreach ($input in $xml.'dunes-script-module'.param) {
            $obj = [VroActionInput]::new()
            $obj.name = $input.n
            $obj.description = $input.'#cdata-section'
            $obj.type = $input.t
            $inputs += $obj
        }
        $vroAction.InputParameters = $inputs
    }

    return $vroAction
}

function ConvertTo-VroActionJs {
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNull()]
        [VroAction]$InputObject
    )

    # being compiling JS file

    $vroActionJs = "/**" + [System.Environment]::NewLine

    # add in description if available

    if ($InputObject.Description){
        foreach ($line in $InputObject.Description.split([System.Environment]::NewLine)){
            $vroActionJs += "* " + $line + [System.Environment]::NewLine
        }
    }

    # add inputs if available

    if ($InputObject.InputParameters){
        foreach ($input in $InputObject.InputParameters) {
            $vroActionJs += "* @param {" + $input.type + "} " + $input.name + " - " + $input.description + [System.Environment]::NewLine
        }
    }

    # additional fields

    $vroActionJs += "* @id " + $InputObject.Id + [System.Environment]::NewLine
    $vroActionJs += "* @version " + $InputObject.Version + [System.Environment]::NewLine
    $vroActionJs += "* @allowedoperations " + $InputObject.AllowedOperations + [System.Environment]::NewLine
 
    # compulsory return field

    $vroActionJs += "* @return {" + $InputObject.OutputType + "}" + [System.Environment]::NewLine
    $vroActionJs += "*/" + [System.Environment]::NewLine

    # add in function with inputs by name

    $vroActionJs += "function " + $InputObject.Name + "("
    $vroActionJs += ($InputObject.InputParameters.name) -join ","
    $vroActionJs += ") {" + [System.Environment]::NewLine
    if ($InputObject.Script) {
        foreach ($line in $InputObject.Script.split([System.Environment]::NewLine)) {
            $vroActionJs += "`t$line" + [System.Environment]::NewLine
        }
    }
    $vroActionJs += "};"

    return $vroActionJs
}

function ConvertFrom-VroActionJs {
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNull()]
        [string[]]$InputObject
    )

    # above validations including from pipeline
    # check there is header start header end function and final line

    # Init

    $vroAction = [VroAction]::new();

    # Regex Extractor

    $patternHeader = '(?smi)\/\*\*\n(\* .*\n)+(\*\/)'
    $patternDescription = "(\/\*\*\n)(\* [^@\n]*[^@]*)(\n)"
    $patternBody = "(?smi)^function .*\n(.*\n)*"
    $patternInputs =  "\* @(?<jsdoctype>param) (?<type>[^}]*}) (?<name>\w+) - (?<description>[^\n]*)"
    $patternReturn =  "\* @(?<jsdoctype>return) (?<type>{[^}]*})"
    $patternOther = "\* @(?<jsdoctype>\w+) (?<description>[^{]*)"

    $jsdocBody = ($InputObject | Select-String -Pattern $patternBody | ForEach-Object { $_.Matches.value }).split([System.Environment]::NewLine)
    $vroAction.Name = $jsdocBody[0].split(" ")[1].split("(")[0]
    $vroAction.Script = ($jsdocBody | Select-Object -Skip 1 | Select-Object -First ($jsdocBody.count - 3) | ForEach-Object { $_ -replace "^\t","" }) -join [System.Environment]::NewLine
    $jsdocHeader = $InputObject | Select-String $patternHeader -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1] } | ForEach-Object { $_.Value }
    $jsDocDescription = $InputObject | Select-String -Pattern $patternDescription -AllMatches | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[2] } | ForEach-Object { $_.Value }
    $vroAction.Description = $jsDocDescription -replace "(?ms)^\* ",""

    # jsdoc comments

    $jsdocComments = @()
    $jsdocHeader.Split([System.Environment]::NewLine) | Select-String -Pattern $patternInputs, $patternReturn , $patternOther |
        Foreach-Object {
            $jsdocComments += [PSCustomObject] @{
                jsdoctype = $_.Matches[0].Groups['jsdoctype'].Value
                type = $_.Matches[0].Groups['type'].Value
                name = $_.Matches[0].Groups['name'].Value
                description = $_.Matches[0].Groups['description'].Value
            }
        }

    # Populate vroaction

    $id = $jsdocComments | Where-Object { $_.jsdoctype -eq "id" }
    
    if ($id){
        $vroAction.Id = $id.description
    }else{
        $vroAction.Id = "{$([guid]::NewGuid().Guid)}".ToUpper()
    }

    # inputs

    $inputs = @()

    foreach ($input in ($jsdocComments | Where-Object { $_.jsdoctype -eq "param" })) {
        $obj = [VroActionInput]::new()
        $obj.name = $input.name
        $obj.description = $input.description                  
        $obj.type = $input.type
        $inputs += $obj
    }
    $vroAction.InputParameters = $inputs

    # version
    $vroAction.Version = ($jsdocComments | Where-Object { $_.jsdoctype -eq "version" }).description

    # allowed operations
    $vroAction.AllowedOperations = ($jsdocComments | Where-Object { $_.jsdoctype -eq "allowedoperations" }).description

    # return type
    $vroAction.OutputType = ($jsdocComments | Where-Object { $_.jsdoctype -eq "return" }).type

    return $vroAction
}

function ConvertTo-VroActionXml {
        param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [VroAction]$inputObject
    )
    # move as many tests as possible up to the top
    # consider output type - currently this script will be null, but maybe it should be the jsdoc path

    $vroActionXml = [xml]'<?xml version="1.0" encoding="UTF-8"?>'

    $xmlElt = $vroActionXml.CreateElement("dunes-script-module")

    $att = $vroActionXml.CreateAttribute("name")
    $att.Value = $inputObject.Name
    $null = $xmlElt.Attributes.Append($att)

    $att = $vroActionXml.CreateAttribute("result-type")
    $att.Value = $inputObject.OutputType.replace("{","").replace("}","")
    $null = $xmlElt.Attributes.Append($att)

    $att = $vroActionXml.CreateAttribute("api-version")
    $att.Value = "6.0.0"
    $null = $xmlElt.Attributes.Append($att)

    $att = $vroActionXml.CreateAttribute("id")
    $att.Value = $inputObject.Id
    $null = $xmlElt.Attributes.Append($att)

    $att = $vroActionXml.CreateAttribute("version")
    $att.Value = $inputObject.Version
    $null = $xmlElt.Attributes.Append($att)

    if (!([string]::IsNullOrWhitespace($inputObject.AllowedOperations))){
        $att = $vroActionXml.CreateAttribute("allowed-operations")
        $att.Value = $inputObject.AllowedOperations
        $null = $xmlElt.Attributes.Append($att)
    }

    $null = $vroActionXml.AppendChild($xmlElt)

    $Node = $vroActionXml.'dunes-script-module'

    # Creation of a node and its text
    if ($inputObject.Description){
        $xmlElt = $vroActionXml.CreateElement("description")
        $xmlCdata = $vroActionXml.CreateCDataSection($inputObject.Description)
        $null = $xmlElt.AppendChild($xmlCdata)
        # Add the node to the document
        $null = $Node.AppendChild($xmlElt)
    }

    ## Populate Inputs from Component Plan

    foreach ($Input in $inputObject.InputParameters){

        # Creation of a node and its text
        $xmlElt = $vroActionXml.CreateElement("param")
        $xmlCdata = $vroActionXml.CreateCDataSection($Input.description)
        $null = $xmlElt.AppendChild($xmlCdata)

        # Creation of an attribute in the principal node
        $xmlAtt = $vroActionXml.CreateAttribute("n")
        $xmlAtt.value = $Input.name
        $null = $xmlElt.Attributes.Append($xmlAtt)

        # Creation of an attribute in the principal node
        $xmlAtt = $vroActionXml.CreateAttribute("t")
        $xmlAtt.value = $Input.type.trim("{").trim("}")
        $null = $xmlElt.Attributes.Append($xmlAtt)

        # Add the node to the document
        $null = $Node.AppendChild($xmlElt)
    }

    if ($inputObject.Script){
        # Creation of a node and its text
        $xmlElt = $vroActionXml.CreateElement("script")
        $xmlCdata = $vroActionXml.CreateCDataSection($inputObject.Script -join [System.Environment]::NewLine)
        $null = $xmlElt.AppendChild($xmlCdata)

        # Creation of an attribute in the principal node
        $xmlAtt = $vroActionXml.CreateAttribute("encoded")
        $xmlAtt.value = "false"
        $null = $xmlElt.Attributes.Append($xmlAtt)

        # Add the node to the document
        $null = $Node.AppendChild($xmlElt)
    }

    return $vroActionXml
}

function Export-VroActionFile {
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true
        )]
        [ValidateNotNull()]
        [string[]]$InputObject,
        [Parameter(
            ValueFromPipelineByPropertyName = $true
        )]
        [string]$exportFolder        
    )

    # create temporary folder
    $tmpWorkingFolder = CreateTemporaryFolder
    $compressFolder = New-Item -Path $tmpWorkingFolder.fullName -Name "$($vroActionXml.'dunes-script-module'.name).action" -Type Directory

    #code $tmpWorkingFolder

    # export content xml
    $vroActionXml.Save("$compressFolder/action-content")
    $actionContent = get-content "$compressFolder/action-content"
    $actionContent = $actionContent | ForEach-Object { $_.replace("<?xml version=`"1.0`" encoding=`"UTF-8`"?>","<?xml version='1.0' encoding='UTF-8'?>") }
    $actionContent | set-content "$compressFolder/action-content" -Encoding bigendianunicode
    $stream = [IO.File]::OpenWrite("$compressFolder/action-content")
    $stream.SetLength($stream.Length - 2)
    $stream.Close()
    $stream.Dispose()

    # export history xml
    $actionHistory  = "<?xml version='1.0' encoding='UTF-8'?>" + [System.Environment]::NewLine
    $actionHistory += "<items>" + [System.Environment]::NewLine
    $actionHistory += "</items>" + [System.Environment]::NewLine
    $actionHistory | Set-Content "$compressFolder/action-history" -Encoding bigendianunicode

    # export info xml
    $actionInfo  = "#" + [System.Environment]::NewLine
    $actionInfo += "#Wed Jul 24 04:55:53 UTC 2019" + [System.Environment]::NewLine
    $actionInfo += "unicode=true" + [System.Environment]::NewLine
    $actionInfo += "owner=" + [System.Environment]::NewLine
    $actionInfo += "version=2.0" + [System.Environment]::NewLine
    $actionInfo += "type=action" + [System.Environment]::NewLine
    $actionInfo += "creator=www.dunes.ch" + [System.Environment]::NewLine
    $actionInfo += "charset=UTF-16" + [System.Environment]::NewLine
    $actionInfo | Set-Content "$compressFolder/action-info" -Encoding utf8

    # compress the folder

    #$compressedFolder = Compress-Archive -Path $compressFolder -DestinationPath "$exportFolder/$($vroActionXml.'dunes-script-module'.name).action" #-Force
    $compressedFolder = [io.compression.zipfile]::CreateFromDirectory($compressFolder, "$exportFolder/$($vroActionXml.'dunes-script-module'.name).action")
    return $compressedFolder
}

function Compare-VroActionContents {
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [String]$OriginalVroActionFile,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNull()]
        [string]$UpdatedVroActionFile
    )

    # create temporary folder
    $tmpWorkingFolder = CreateTemporaryFolder
    $original = New-Item -Path $tmpWorkingFolder.fullName -Name "original" -Type Directory
    $updated = New-Item -Path $tmpWorkingFolder.fullName -Name "updated" -Type Directory

    #code $tmpWorkingFolder

    Expand-Archive -Path $OriginalVroActionFile -DestinationPath $original
    Expand-Archive -Path $UpdatedVroActionFile -DestinationPath $updated

    ([xml](Get-Content $original/action-content)).Save("$original/action-content")
    ([xml](Get-Content $updated/action-content)).Save("$updated/action-content")

    $originalFileHash = Get-FileHash -Path $original/action-content
    $updatedFileHash = Get-FileHash -Path $updated/action-content
    
    # finalise
    
    Write-Debug $tmpWorkingFolder.fullName
    Write-Debug $originalFileHash.Hash
    Write-Debug $updatedFileHash.Hash

    if ($originalFileHash.Hash -eq $updatedFileHash.Hash){
        $tmpWorkingFolder | Remove-Item -Recurse -Force -Confirm:$false
        return $true
    }
    
    # attempt number : dropping the allowed operations VEF - sometimes unpredictable outputs

    $diff = Compare-Object -ReferenceObject $original/action-cont -DifferenceObject $updated/action-content
    $vcfLineEndOriginal = (Get-Content "$original/action-content")[1].Split(" ")[-1].split("=")[0]

    if ( ($diff.count -eq 2) -and ( $vcfLineEndOriginal -eq "allowed-operations" ) ){
        $originalFile = Get-Content $original/action-content
        $updatedFile = Get-Content $updated/action-content

        $originalFile[1] = $updatedFile[1]

        $originalFile | set-content "$original/action-content" -Encoding bigendianunicode
        $stream = [IO.File]::OpenWrite("$original/action-content")
        $stream.SetLength($stream.Length - 2)
        $stream.Close()
        $stream.Dispose()

        ([xml](Get-Content $original/action-content)).Save("$original/action-content")

        $originalFileHash = Get-FileHash -Path $original/action-content
        $updatedFileHash = Get-FileHash -Path $updated/action-content

        if ($originalFileHash.Hash -eq $updatedFileHash.Hash){
            $tmpWorkingFolder | Remove-Item -Recurse -Force -Confirm:$false
            return $true
        }
    }
    return $false
}

function Export-VroIde {
    param (
        [Parameter(
            Mandatory = $false
        )]
        [string]$vroIdeFolder,
        [switch]$keepWorkingFolder
    )

    Write-Debug "### Beginng Export VRO IDE"

    if (!$vROConnection){
        throw "VRO Connection Required"
    }

    if ($vroIdeFolder){
        $vroIdeFolder = Get-Item $vroIdeFolder
    }else{
        Write-Debug "No Folder Provided Generating a Random one"
        $vroIdeFolder = CreateTemporaryFolder
    }

    $workingFolder = New-Item -ItemType Directory -Path $vroIdeFolder -Name "$([guid]::NewGuid().Guid)".ToUpper()

    $vroActionHeaders = Get-vROAction | Where-Object { $_.FQN -notlike "com.vmware*" }

    # export vro action headers 

    $vroActionHeaders | ConvertTo-Json | set-content (Join-Path -Path $vroIdeFolder -ChildPath "vroActionHeaders.json")

    # Creating Folders

    foreach ($vroActionHeader in $vroActionHeaders){
        $vroActionHeader = $vroActionHeader -as [VroAction]
        Write-Debug "Creating Folders : $($vroActionHeader.FQN)"
        if (!(Test-Path $vroActionHeader.modulePath($vroIdeFolder))){
            $null = New-Item -ItemType Directory -Path $vroActionHeader.modulePath($vroIdeFolder)
        }
        if (!(Test-Path $vroActionHeader.modulePath($workingFolder))){
            $null = New-Item -ItemType Directory -Path $vroActionHeader.modulePath($workingFolder)
        }
    }

    # Downloading Actions

    foreach ($vroActionHeader in $vroActionHeaders){
        $vroActionHeader = $vroActionHeader -as [VroAction]
        Write-Debug "Downloading Action : $($vroActionHeader.FQN)"
        $null = Export-vROAction -Id $vroActionHeader.Id -Path $vroActionHeader.modulePath($workingFolder)
    }

    # Expanding Actions

    foreach ($vroActionHeader in $vroActionHeaders){
        $vroActionHeader = $vroActionHeader -as [VroAction]
        Write-Debug "Expanding Action : $($vroActionHeader.FQN)"
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $actionContentFile = [System.IO.Compression.ZipFile]::OpenRead($vroActionHeader.filePath($workingFolder,"action")).Entries | Where-Object { $_.FullName -eq "action-content"}
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($actionContentFile, $vroActionHeader.filePath($workingFolder,"xml"), $true)
    }

    # Import XML convert to jsdoc convert save
    foreach ($vroActionHeader in $vroActionHeaders){
        $vroActionHeader = $vroActionHeader -as [VroAction]
        Write-Debug "Convert from XML to JS and Save for Action : $($vroActionHeader.FQN)"
        $vroActionXml = [xml](get-content $vroActionHeader.filePath($workingFolder,"xml"))
        $vroAction = ConvertFrom-VroActionXml -InputObject $vroActionXml
        $vroAction | ConvertTo-Json -Depth 99 | Set-Content $vroActionHeader.filePath($workingFolder,"json")
        $vroActionJs = ConvertTo-VroActionJs -InputObject $vroAction
        $vroActionJs | set-content $vroActionHeader.filePath($vroIdeFolder,"js")
    }

    if ($keepWorkingFolder){
        Write-Debug "Working Folder not deleted : $($workingFolder.FullName)"        
    }else{
        $null = Remove-Item $workingFolder -Recurse -Force -Confirm:$false
    }

    return $vroIdeFolder
}

function Import-VroIde {
    param (
        [Parameter(
            Mandatory = $true
        )]
        [string]$vroIdeFolder,
        [switch]$keepWorkingFolder
    )

    Write-Debug "### Beginng Import VRO IDE"

    if (!$vROConnection){
        throw "VRO Connection Required"
    }

    if (!(Test-Path "$vroIdeFolder/vroActionHeaders.json")){
        throw "vroActionHeaders.json file required in the working folder"
    }else{
        $vroActionHeaders = Get-Content (Join-Path -Path $vroIdeFolder -ChildPath "vroActionHeaders.json") -Raw | ConvertFrom-Json
    }

    $vroActionHeaders | Select-Object -First 5

    $workingFolder = New-Item -ItemType Directory -Path $vroIdeFolder -Name ([guid]::NewGuid().Guid).ToUpper()

    # Creating Folders

    foreach ($vroActionHeader in $vroActionHeaders){
        $vroActionHeader = $vroActionHeader -as [VroAction]
        Write-Debug "Creating Folders : $($vroActionHeader.FQN)"
        if (!(Test-Path $vroActionHeader.modulePath($vroIdeFolder))){
            $null = New-Item -ItemType Directory -Path $vroActionHeader.modulePath($vroIdeFolder)
        }
        if (!(Test-Path $vroActionHeader.modulePath($workingFolder))){
            $null = New-Item -ItemType Directory -Path $vroActionHeader.modulePath($workingFolder)
        }
    }

    # Downloading Actions

    foreach ($vroActionHeader in $vroActionHeaders){
        $vroActionHeader = $vroActionHeader -as [VroAction]
        Write-Debug "Downloading Action : $($vroActionHeader.FQN)"
        $null = Export-vROAction -Id $vroActionHeader.Id -Path $vroActionHeader.modulePath($workingFolder)
    }

    # Import jsodc convert to xml convert save and export to action
    foreach ($vroActionHeader in $vroActionHeaders){
        $vroActionHeader = $vroActionHeader -as [VroAction]
        Write-Debug "Convert from XML to JS and Save for Action : $($vroActionHeader.FQN)"
        $vroActionJs = Get-Content $vroActionHeader.filePath($vroIdeFolder,"js") -Raw
        $vroAction = ConvertFrom-VroActionJs -InputObject $vroActionJs
        $vroAction | ConvertTo-Json -Depth 99 | Set-Content $vroActionHeader.filePath($workingFolder,"json")
        $vroActionXml = ConvertTo-VroActionXml -InputObject $vroAction
        $vroActionXml.Save($vroActionHeader.filePath($workingFolder,"xml"))
        Export-VroActionFile -InputObject $vroActionXml -exportFolder $vroActionHeader.modulePath($vroIdeFolder)
    }

    # Compare and upload on difference

    foreach ($vroActionHeader in $vroActionHeaders){
        $vroActionHeader = $vroActionHeader -as [VroAction]
        $compareResult = Compare-VroActionContents -OriginalVroActionFile $vroActionHeader.filePath($workingFolder,"action") -UpdatedVroActionFile $vroActionHeader.filePath($vroIdeFolder,"action") -Debug
        if ($compareResult){
            Write-Debug "Comparing $($vroActionHeader.Name) : would not be updated - file hash identical"
        }else{
            Write-Debug "Comparing $($vroActionHeader.Name) : would be updated - file hash not identical"
            Import-vROAction -CategoryName $vroActionHeader.FQN.split("/")[0] -File $vroActionHeader.filePath($vroIdeFolder,"action") #-Overwrite -WhatIf
        }
        Remove-Item -Path $vroActionHeader.filePath($vroIdeFolder,"action") -Confirm:$false
    }

    if ($keepWorkingFolder){
        Write-Debug "Working Folder not deleted : $($workingFolder.FullName)"        
    }else{
        $null = Remove-Item $workingFolder -Recurse -Force -Confirm:$false
    }
}