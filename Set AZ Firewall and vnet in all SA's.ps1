# Get VNET subnets with storage endpoints
#Codebase used from MSFT Fabien Gilbert
#Code locks down to specific vnets within a resource group
#WILL add vnets subnets to storage accounts even if service endpoints are NOT configured.

$rsgs = Get-AzResourceGroup

foreach ($rsg in $rsgs){
$vnets = Get-AzVirtualNetwork -ResourceGroupName $rsg.ResourceGroupName
$vnetSubRules = @()
foreach ($vnet in $vnets) { 
    $snwse = 0
    foreach ($vnetSub in $vnet.Subnets) {
        
            $vnetSubRules += @{
                "VirtualNetworkResourceId" = $vnetSub.Id
                "Action" = "allow"
            }
            $snwse++
            
        }
     
    
    }   
    Write-Output ("found " + $snwse + " subnets with storage account service endpoint in VNET " + [char]34 + $vnet.Name + [char]34 + "...")
# Close the loop if needed }
# Get Storage Accounts
$storaccts = Get-AzStorageAccount -ResourceGroupName $rsg.ResourceGroupName
# Loop through storage accounts
foreach($storacct in $storaccts){
    Write-Output ("configuring storage account firewall on " + [char]34 + $storacct.StorageAccountName + [char]34 + " current default action: " + $storacct.NetworkRuleSet.DefaultAction)
    $updateNetworkRules = Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $storacct.ResourceGroupName `
                                                                -AccountName $storacct.StorageAccountName `
                                                                -Bypass AzureServices,Logging,Metrics `
                                                                -DefaultAction Deny `
                                                                -IpRule $publicIpRules `
                                                                -VirtualNetworkRule $vnetSubRules `
                                                                -WarningAction:SilentlyContinue
}
}
