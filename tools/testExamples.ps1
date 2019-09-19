Connect-vROServer -Server  vrax.greenscript.net -IgnoreCertRequirements -Port 443 -Username administrator@vsphere.local
$result = Invoke-vROAction -Id d064c04d-93a4-4290-b5bf-063ec1dbe5a2
$result | ConvertTo-Json -Depth 99
