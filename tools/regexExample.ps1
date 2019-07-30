## JSDOC Regex 

# header and description

$patternHeader = '(?smi)\/\*\*\n(\* .*\n)+(\*\/)'
$patternDescription = "\/\*\*(\n(\* )[^@].*)*"

$fileName = '/Users/garryhughes/GIT/my-actions/src/pso.test.gh/exportedImported/exportedImported.js'
$fileContent = Get-Content $fileName -Raw
$jsdocBody = $fileContent -replace '(?smi)\/\*\*\n(\* .*\n)+(\*\/)',''
$jsdocHeader = $fileContent | Select-String '(?smi)\/\*\*\n(\* .*\n)+(\*\/)' -AllMatches | %{ $_.Matches } | %{ $_.Groups[1] } | %{ $_.Value }
$jsDocDescription = $fileContent | Select-String -Pattern "(\/\*\*\n)(\* [^@]*\n)*" -AllMatches | %{ $_.Matches } | %{ $_.Groups[2] } | %{ $_.Value }
$jsDocDescription = $jsDocDescription.split([System.Environment]::NewLine) | % { $_ -replace "^\* ","" }

# jsdoc comments

$patternInputs =  "\* @(?<jsdoctype>param) (?<type>[^}]*}) (?<name>\w+) - (?<description>[^\n]*)"
$patternReturn =  "\* @(?<jsdoctype>return) (?<type>{[^}]*})"
$patternOther = "\* @(?<jsdoctype>\w+) (?<description>[^{]*)"

$jsdocComments = @()
$fileContent.Split([System.Environment]::NewLine) | Select-String -Pattern $patternInputs, $patternReturn , $patternOther |
    Foreach-Object {
        $jsdocComments += [PSCustomObject] @{
            jsdoctype = $_.Matches[0].Groups['jsdoctype'].Value
            type = $_.Matches[0].Groups['type'].Value
            name = $_.Matches[0].Groups['name'].Value
            description = $_.Matches[0].Groups['description'].Value
        }
    }
$jsdocComments | Format-Table