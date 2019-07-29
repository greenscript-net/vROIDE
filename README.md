# vROIDE

PowerShell Module housing a set of functions designed to assist with the creation and update of VMware VRO Actions.

There are 2 master functions that import and export Actions for editing locally.

## Export-VroIde

- Downloads and saves all actions to local system in a folder structure aligning with vro modules
- Extracts the XML content from each of the actions
- Converts the XML to a Javascript file with JSDOC annotation.

## Import-VroIde

- Converts the Javascript JSDOC to VRO compatible XML.
- Compiles and saves the XML to VRO action format.
- Downloads recent copies of the VRO actions
- Expands the download actions to XML
- Does a File Hash compare of the VRO XML and the Javascript JSDOC converted XML
- If different, will upload the file to VRO.
