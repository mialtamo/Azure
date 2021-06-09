#Connect-AzAccount
Write-Host "*************************************************************************************************" -ForegroundColor blue
Write-Host " "
Write-Host "Welcome to the Azure Storage Account Firewall Activation and Virtual Network Configuration System" -ForegroundColor blue
Write-Host " "
Write-Host "To Begin run Start-AzSAFWConfig" -ForegroundColor Blue
Write-Host " "
Write-Host "*************************************************************************************************" -ForegroundColor Blue

Function Start-AzSAFWConfig {
    Write-Host "[Start-AzSAFWConfig] Started..." -ForegroundColor Blue
Do {
    $passive = Read-Host -Prompt "Should this be a passive Scan Only? ( (P)assive or (E)nforce or (I)nformation )"
If ($passive -match "I"){
Write-Host "Information: By selecting passive scanning it will simply report findings and not attempt to make any changes to storage accounts or virtual networks in ANY capacity. If you select Enforce you will being making the necessary changes discovered in passive Mode. " -ForegroundColor Green
}
elseIf ($passive -match "E"){
    Write-Host "This scan will NOT be passive. Ctrl+C to stop this before countdown" -ForegroundColor red
    $delay = 10
    while ($delay -ge 0){
        Write-Host "Seconds Remaining: $($delay)" -ForegroundColor red
        start-sleep 1
        $delay -= 1
    }
Write-Host "Begin Non-Passive sweep" -ForegroundColor Red
}

elseIf ($passive -match "P"){

Write-Host "Passive Scan selected, this will simply report findings" -ForegroundColor green
 #Loop through each resource group
$rsgs = Get-AzResourceGroup
$foundSA = 0
$foundVN = 0
foreach ($rsg in $rsgs){
Write-Host "Scanning the current Azure Resource Group named ..... < $($rsg.ResourceGroupName) > for any Storage Accounts where the firewall is set to (ALLOW) and for any Virtual Networks where the Microsoft.Storage Service Endpoint is missing" -ForegroundColor green
Write-Host ""
Write-Host "Scanning for Storage Accounts.... That meet our requirements..." -ForegroundColor Blue
$azureSAs = Get-AzStorageAccount -ResourceGroupName $rsg.ResourceGroupName | where-object {$_.NetworkRuleSet.DefaultAction -eq "Allow"}
foreach ($azureSA in $azureSAs)
{
If ($azureSA){
Write-Host "Storage Account found named: $($azureSA.StorageAccountName)" -ForegroundColor yellow
Write-Host "Firewall Status: $($azureSA.NetworkRuleSet.DefaultAction)" -ForegroundColor yellow
$foundSA++
}
else{
    Write-Host "No Azure Storage Account found that matched our needs within <$($rsg.ResourceGroupName) >" -foregroundcolor green
} #End If statement for AzureSA
} #End foreach loop AzureSA
If($azureSAs){
    ######################STARTING VNET SEARCH FOR WHEN A RESOURCE GROUP CONTAINS A STORAGE ACCOUNT ##################################
Write-Host "Scanning for Virtual Networks.... That meet our requirements..." -ForegroundColor Blue
$vnets = Get-AzVirtualNetwork -ResourceGroupName $rsg.ResourceGroupName
foreach ($vnet in $vnets) {
If ($vnet.Subnets.ServiceEndpoints.Service -notcontains "Microsoft.Storage") {
    Write-Host "This virtual network does NOT have the service endpoint listed as REQUIRED" $vnet.name -ForegroundColor yellow
    Write-Host "Here are the Service Endpoints discovered for this vnet's subnets:" -ForegroundColor blue
    $vnet.Subnets.ServiceEndpoints.Service
    $foundVN++
} #End if statement vnet
else {
    Write-Host "No Azure Virtual Networks found that matched our needs within <$($rsg.ResourceGroupName) > where storage account < $($azureSA.StorageAccountName)> " -foregroundcolor green
}
} #End foreach loop vnet
######################ENDING VNET SEARCH FOR WHEN A RESOURCE GROUP CONTAINS A STORAGE ACCOUNT ##################################
}
else {
    Write-Host "No Storage Account was discovered" -ForegroundColor red
}
}#End RSG Foreach Loop
Write-Host "Passive Scanning Complete...." -ForegroundColor Blue
Write-Host "Building Report....Standby" -ForegroundColor Blue
start-sleep 2
Write-Host "*************************************************************************************************" -ForegroundColor Blue
Write-Host ""
Write-Host "                                           REPORT FINDINGS" -ForegroundColor Blue
Write-Host "-------------------------------------------------------------------------------------------------" -Foregroundcolor Blue
Write-Host "                        Total Number of Storage Accounts found that need correction: $($foundSA) " -ForegroundColor Blue
Write-Host "" 
Write-Host "                        Total Number of Virtual Networks found that need correction: $($foundVN) " -ForegroundColor Blue
Write-Host "" 
Write-Host ""
Write-Host "*************************************************************************************************" -ForegroundColor Blue

} #End $passive Yes


    else{
  Write-Host  "Incorrect Option Specified" -ForegroundColor red
}
} Until ($passive -match "P" -or $passive -match "E") #End Do Loop

}#end Function
