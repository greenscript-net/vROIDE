$moduleName = "pso.vmware.nsxt.security"
$actionName = "testMe2"

$moduleFolder = Join-Path $vroIdeFolder -ChildPath "src" -AdditionalChildPath $moduleName
$actionFile = Join-Path $moduleFolder -ChildPath "$actionName.js"

$actionContent = @"
/**
* @param {REST:RESTHost} restHost - why the Rest Host
* @param {string} name - why the name
* @version 0.0.0
* @allowedoperations 
* @return {string}
*/
function $actionName(restHost,name) {
`t// Comment line !!;
`treturn 'Successful Action';
};
"@

$actionContent | Set-Content $actionFile