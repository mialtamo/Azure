#Connect-AzAccount
Select-AzSubscription -SubscriptionName ES-CS-CUS-EXT-mialtamo
Write-Host "*************************************************************************************************" -ForegroundColor blue
Write-Host " "
Write-Host "Welcome to the Azure Storage Account Firewall Activation and Virtual Network Configuration System" -ForegroundColor blue
Write-Host " "
Write-Host "To Begin run Start-AZStorageScan" -ForegroundColor Blue
Write-Host " "
Write-Host "MODULE REQUIREMENTS: AZ.RESOURCES, AZ.NETWORK AZ STORAGE" -ForegroundColor Blue
Write-Host "WARNING: USE THIS SCRIPT AT YOUR OWN RISK. "
Write-Host " "
Write-Host "*************************************************************************************************" -ForegroundColor Blue
[System.Collections.ArrayList]$global:vnetSubhash=@()
$addEndPoint = @("Microsoft.Storage")
Function Start-AZStorageScan {
        $subs = Get-AzSubscription
            foreach ($sub in $subs){
                Select-AzSubscription -SubscriptionName $sub.Name
                $rsgs = Get-AZResourceGroup 
                foreach ($rsgvnet in $rsgs | Where-Object {$_.ResourceGroupName -notmatch "NetworkWatcher" -and $_.ResourceGroupName -match "-NET"} )
                {
                    Write-Host ""
                    Write-Host "[INFORMATIONAL] The Virtual Network Resource Group should be: $($rsgvnet.ResourceGroupName)" -ForegroundColor blue
                    $vnets = Get-AZVirtualNetwork -ResourceGroupName $rsgvnet.ResourceGroupName
                    $match = $rsgvnet.ResourceGroupName.Substring(0,$rsgvnet.ResourceGroupName.IndexOf("-NET"))
                    Write-Host "[DISCOVERY] This is the match: $($match)" -ForegroundColor yellow
                        If ($vnets.count -gt 0)
                            {
                    Write-Host "[DISCOVERY] This is the Virtual Network Discovered < $($vnets.Name -join ",") >" -ForegroundColor yellow
                    Write-Host "[DISCOVERY] Establishing the subnets for Virtual Network < $($vnets.Name -join ",") >" -ForegroundColor yellow
                    foreach ($vnet in $vnets){
                            foreach($vnetsub in $vnet.subnets)
                                    {
                                    $global:vnetSubhash += @{
                                    "VirtualNetworkResourceId" = $vnetSub.Id
                                    "Action" = "allow"
                                                        }
                                    Write-Host "[DISCOVERY] Checking if Subnets for Virtual Network < $($vnet.Name) > have the 'Microsoft.Storage' Service Endpoint bound" -ForegroundColor yellow
                                    start-sleep 1
                                    If($vnetsub.ServiceEndpoints.service -notcontains "Microsoft.Storage"){
                                    Write-Host "[SETTING] Setting Virtual Network < $($vnet.Name) > subnet: $($vnetsub.name)" -ForegroundColor green
                                    Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $vnetSub.Name -AddressPrefix $vnetSub.AddressPrefix -ServiceEndpoint $addEndPoint -WarningAction silentlyContinue | Out-Null
                                    Set-AzVirtualNetwork -VirtualNetwork $vnet | Out-Null
                                    }
                                    else{
                                        Write-Host "[ALERT] The 'Microsoft.Storage' endpoint on Virtual Network < $($vnet.Name) > pre-exists" -ForegroundColor red
                                    }
                                    }
                                }

                    }
                    else{
                        Write-Host "[ALERT] No Virtual Networks found within the < $($rsgvnet.ResourceGroupName) >" -ForegroundColor red
                    }
                
                    foreach($rsg in $rsgs | Where-Object {$_.ResourceGroupName -match $match -and $_.ResourceGroupName -notmatch "-NET"})
                    {
                        Write-Host "[INFORMATIONAL] Locating Storage Accounts in < $($rsg.ResourceGroupName) > where the Virtual Network is located in this Resource Group $($rsgvnet.ResourceGroupName)" -ForegroundColor blue
                        $azureSAs = Get-AzStorageAccount -ResourceGroupName $rsg.ResourceGroupName | where-object {$_.NetworkRuleSet.DefaultAction -eq "Allow"}
                        If($azureSAs.count -gt 0){
                                Foreach($azureSA in $azureSAs){
                                Write-Host "[DISCOVERY] Found the following Storage Accounts < $($azureSAs.StorageAccountName -join ",") >" -ForegroundColor yellow
                                Write-Host "[SETTING] Setting Virtual Network <$($vnets.name -join ",")> to Storage Account < $($azureSA.StorageAccountName) > " -ForegroundColor green
                                $updateNetworkRules = Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $azureSA.ResourceGroupName -AccountName $azureSA.StorageAccountName -Bypass AzureServices,Logging,Metrics -IpRule $publicIpRules -DefaultAction Deny -VirtualNetworkRule ($vnetSubhash | Where-Object {$_.Values -match $rsgvnet.resourcegroupname}) #-WarningAction:SilentlyContinue
                            
                                                    }

                                                        }
                         else{
                            Write-Host "[ALERT] No Storage Account Found" -ForegroundColor red
                             }

                    }

                }

Write-Host ""
                                    }           #end subs subscription            

     
                                        } #end Function
Start-AZStorageScan
