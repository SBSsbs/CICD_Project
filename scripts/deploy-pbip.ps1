$workspaceName = "Assurance Véhicule – DEV"
$projectRoot = $env:GITHUB_WORKSPACE
$semanticModelPath = Join-Path $projectRoot "Analyse_des_RAA_Init.SemanticModel"
$reportPath = Join-Path $projectRoot "Analyse_des_RAA_Init.Report"
New-Item -ItemType Directory -Path ".\modules" -ErrorAction SilentlyContinue | Out-Null
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psm1" `
  -OutFile ".\modules\FabricPS-PBIP.psm1"
Invoke-WebRequest `
  -Uri "https://raw.githubusercontent.com/microsoft/Analysis-Services/master/pbidevmode/fabricps-pbip/FabricPS-PBIP.psd1" `
  -OutFile ".\modules\FabricPS-PBIP.psd1"
if (-not (Get-Module Az.Accounts -ListAvailable)) {
    Install-Module Az.Accounts -Scope CurrentUser -Force -AllowClobber
}
Import-Module ".\modules\FabricPS-PBIP.psm1" -Force
$securePassword = ConvertTo-SecureString $env:PBI_CLIENT_SECRET -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($env:PBI_CLIENT_ID, $securePassword)
Connect-AzAccount `
  -ServicePrincipal `
  -Tenant $env:PBI_TENANT_ID `
  -Credential $credential
Set-FabricAuthToken
$workspaceId = New-FabricWorkspace -name $workspaceName -skipErrorIfExists
$semanticModelImport = Import-FabricItem `
  -workspaceId $workspaceId `
  -path $semanticModelPath
$reportImport = Import-FabricItem `
  -workspaceId $workspaceId `
  -path $reportPath `
  -itemProperties @{"semanticModelId" = $semanticModelImport.Id}
Write-Host "Deployment completed successfully."
