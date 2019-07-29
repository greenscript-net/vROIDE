$fileName = '/Users/garryhughes/GIT/my-actions/src/pso.test.gh/exportedImported/exportedImported.js'
$fileContent = Get-Content -Raw $fileName
$fileContent | Select-String '(?smi)\/\*\*\n(\*\ .*\n)+' -AllMatches | %{ $_.Matches } | %{ $_.Groups[1] } | %{ $_.Value }

$fileContent |
    Select-String '(?smi)ap71xx[^!]+!' -AllMatches |
    %{ $_.Matches } |
    %{ $_.Value }

    $fileContent |
    Select-String '(?smi)ap71xx([.*]+!)' -AllMatches |
    %{ $_.Matches } |
    %{ $_.Groups[1] } |
    %{ $_.Value }


$firstLastPattern = "^(?<first>\w+) (?<last>[^-]+)-(?<followers>\d+) (?<handle>@.+)"
$lastFirstPattern = "^(?<last>[^\s,]+),\s+(?<first>[^-]+)-(?<handle>@[^,]+),(?<followers>\d+)"

$firstLine
$lastLine

$pattern = "^\* \@param {<paramtype>\w+} <paramname>\w+ - .*$"

$paramPattern = "^\* \@param {[\w  :]+} \w+ - .*$"
$returnPattern = "^\* \@return {[\w  :\/]+}$"
$descriptionPattern = ""

return /[ \t]*\/\*\*\s*\n([^*]*(\*[^/])?)*\*\//g;

Get-ChildItem fileName |
     Select-String -Pattern $firstLastPattern, $lastFirstPattern |
    Foreach-Object {
        # here we access the groups by name instead of by index
        $first, $last, $followers, $handle = $_.Matches[0].Groups['first', 'last', 'followers', 'handle'].Value
        [PSCustomObject] @{
            FirstName = $first
            LastName = $last
            Handle = $handle
            TwitterFollowers = [int] $followers
        }
    }