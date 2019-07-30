## JSDOC Regex 

$fileName = '/Users/garryhughes/GIT/my-actions/src/pso.test.gh/exportedImported/exportedImported.js'

# header and description

$patternHeader = '(?smi)\/\*\*\n(\* .*\n)+(\*\/)'
$patternDescription = "(\/\*\*\n)(\* [^@]*\n)*"
$patternBody = "(?smi)^function .*\n(.*\n)*"
$patternInputs =  "\* @(?<jsdoctype>param) (?<type>[^}]*}) (?<name>\w+) - (?<description>[^\n]*)"
$patternReturn =  "\* @(?<jsdoctype>return) (?<type>{[^}]*})"
$patternOther = "\* @(?<jsdoctype>\w+) (?<description>[^{]*)"

$fileContent = Get-Content $fileName -Raw
$jsdocBody = ($fileContent | Select-String -Pattern $patternBody |  % { $_.Matches.value }).split([System.Environment]::NewLine) 
$jsdocBody = ($jsdocBody | Select-Object -Skip 1 | % { $_ -replace "^\t","" }) -join [System.Environment]::NewLine
$jsdocHeader = $fileContent | Select-String $patternHeader -AllMatches | % { $_.Matches } | %{ $_.Groups[1] } | %{ $_.Value }
$jsDocDescription = $fileContent | Select-String -Pattern $patternDescription -AllMatches | %{ $_.Matches } | %{ $_.Groups[2] } | %{ $_.Value }
$jsDocDescription = $jsDocDescription.split([System.Environment]::NewLine) | % { $_ -replace "^\* ","" }

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

Write-Host "##################"
$jsdocHeader
Write-Host "##################"
$jsdocBody
Write-Host "##################"
$jsdocComments