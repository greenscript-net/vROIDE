[![Build Status](https://dev.azure.com/greenscript/vROIDE/_apis/build/status/greenscript-net.vROIDE?branchName=master)](https://dev.azure.com/greenscript/vROIDE/_build/latest?definitionId=5&branchName=master)

# vROIDE

PowerShell Module housing a set of functions designed to assist with the creation and update of VMware VRO Actions.

There are 2 master functions that import and export Actions for editing locally.

## Export-VroIde

- Downloads and saves all actions to local system in a folder structure aligning with vro modules
- Extracts the XML content from each of the actions
- Converts the XML to a Javascript file with JSDOC annotation
- As an addition converts the XML to markdown format in a separate folder
- Creates the initial stub for some automated testing

The following folder structure is produced, ready to turned into a GIT project and tested.
It will also auto populate some markdown as documentation.

- docs
  - module01
    - action01.md
    - action02.md
  - module02
    - action03.md
    - action04.md
- src
  - module01
    - action01.js
    - action02.js
  - module02
    - action03.js
    - action04.js
- tests
  - module01
    - action01.test.js
    - action02.test.js
  - module02
    - action03.test.js
    - action04.test.js
 

## Import-VroIde

- Converts the Javascript JSDOC to VRO compatible XML.
- Compiles and saves the XML to VRO action format.
- Downloads recent copies of the VRO actions
- Expands the download actions to XML
- Does a File Hash compare of the VRO XML and the Javascript JSDOC converted XML
- If different, will upload the file to VRO.


