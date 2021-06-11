#Connect-AzAccount
Write-Host "*************************************************************************************************" -ForegroundColor blue
Write-Host " "
Write-Host "Welcome to the Azure Storage Account Firewall Activation and Virtual Network Configuration System" -ForegroundColor blue
Write-Host " "
Write-Host "To Begin run Start-AzSAFWConfig" -ForegroundColor Blue
Write-Host " "
Write-Host "*************************************************************************************************" -ForegroundColor Blue
Function Start-AzSAFWConfig 
{

    Write-Host "[Start-AzSAFWConfig] Started..." -ForegroundColor Blue
Do 
    {
        $passive = Read-Host -Prompt "Should this be a passive Scan Only? ( (P)assive or (E)nforce or (I)nformation )"
    If ($passive -match "I"){
Write-Host "Information: By selecting passive scanning it will simply report findings and not attempt to make any changes to storage accounts or virtual networks in ANY capacity. If you select Enforce you will being making the necessary changes discovered in passive Mode. " -ForegroundColor Green
                            }
elseIf ($passive -match "E")
                                {
                                        Write-Host "This scan will NOT be passive. Ctrl+C to stop this before countdown" -ForegroundColor red
                                        $delay = 10
                                        $addEndPoint = @("Microsoft.Storage")
                                        $enforcedvn = 0
                                        [System.Collections.ArrayList]$global:vnetSubRules=@()
                                       $filtered=@()
                                        while ($delay -ge 0){
                                            Write-Host "Seconds Remaining: $($delay)" -ForegroundColor red
                                            start-sleep 1
                                                    $delay -= 1
                                                            }
    Write-Host "[ENFORCE] Checking if Passive scan was run" -ForegroundColor red
    start-sleep 1
                                        If($DiscoveredSAs.Count -gt 0 -and $DiscoveredVNs.Count -gt 0)
                                                                {
 Write-Host "[ENFORCE] Storage Accounts and Virtual Networks previously discovered" -ForegroundColor red
 Write-Host "[ENFORCE] Will attempt to Enforce on known bad configuration" -ForegroundColor red
Write-Host "[ENFORCE] Starting enforcement on Virtual Networks" -ForegroundColor red
Write-Host ""

foreach ($DiscoveredVN in $DiscoveredVNs)
    {
    foreach ($vnetSub in $DiscoveredVN.Subnets)
            {
    Write-Host "[ENFORCE] Virtual Network < $($DiscoveredVN.Name) > and the subnet < $($vnetsub.Name) > will have the service endpoint < $($addEndPoint) > added..." -ForegroundColor red
    Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $DiscoveredVN -Name $vnetSub.Name -AddressPrefix $vnetSub.AddressPrefix -ServiceEndpoint $addEndPoint -WarningAction silentlyContinue | Out-Null
    Set-AzVirtualNetwork -VirtualNetwork $DiscoveredVN | Out-Null
    Write-Host "[ENFORCE] SUCCESS Virtual Network < $($DiscoveredVN.Name) > and the subnet < $($vnetsub.Name) > has added the service endpoint < $($addEndPoint) >" -ForegroundColor green
    $global:vnetSubRules += @{
        "VirtualNetworkResourceId" = $vnetSub.Id
        "Action" = "allow"
    }

        $enforcedvn++
            } #end subnet foreach
            Write-Host "[ENFORCE] Starting enforcement on Storage Accounts" -ForegroundColor red
            start-sleep 1
            foreach ($DiscoveredSA in $DiscoveredSAs)
                    {
                    if($DiscoveredSA.ResourceGroupName -eq $DiscoveredVN.ResourceGroupName){
                            Write-Host "[ENFORCE] Storage Account < $($DiscoveredSA.StorageAccountName) > will have the below subnets added to the approved firewall list and have the firewall activated" -ForegroundColor red | Out-String
                            start-sleep 10 
                            $updateNetworkRules = Update-AzStorageAccountNetworkRuleSet -ResourceGroupName $DiscoveredSA.ResourceGroupName -AccountName $DiscoveredSA.StorageAccountName -Bypass AzureServices,Logging,Metrics -IpRule $publicIpRules -DefaultAction Deny -VirtualNetworkRule ($vnetSubRules | ? {$_.Values -match $DiscoveredSA.ResourceGroupName}) -WarningAction:SilentlyContinue
                    }
                    
                    
    } #End Foreach storage account
    }#end foreach on discovery vnet


                                                            
} # Closes gt 0 and gt 0

                                                                    elseIf($DiscoveredSAs.Count -gt 0)
                                                                        {
                                                                Write-Host "[ENFORCE] Storage Accounts previously discovered" -ForegroundColor red
                                                                                        }
                                                            elseIf ($DiscoveredVNs.Count -gt 0)
                                                                                {
                                                            Write-Host "[ENFORCE] Virtual Networks previously discovered" -ForegroundColor red
                                                                foreach ($DiscoveredVN in $DiscoveredVNs)
                                                                                {
                                                                                        foreach ($vnetSub in $DiscoveredVN.Subnets)
                                                                                            {
                                                                                            Write-Host "[ENFORCE] Virtual Network < $($DiscoveredVN.Name) > and the subnet < $($vnetsub.Name) > will have the service endpoint < $($addEndPoint) > added..." -ForegroundColor red
                                                                                                    Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $DiscoveredVN -Name $vnetSub.Name -AddressPrefix $vnetSub.AddressPrefix -ServiceEndpoint $addEndPoint -WarningAction silentlyContinue | Out-Null
                                                                                                    Set-AzVirtualNetwork -VirtualNetwork $DiscoveredVN | Out-Null
                                                                                                    Write-Host "[ENFORCE] SUCCESS Virtual Network < $($DiscoveredVN.Name) > and the subnet < $($vnetsub.Name) > has added the service endpoint < $($addEndPoint) >" -ForegroundColor green
                                                                                                $enforcedvn++
                                                                                            }
                                                                                        }
                                                                                        }#End foreach discoveredVN


} #End Passive E Loop
elseIf ($passive -match "P")
                                {
Write-Host "[PASSIVE] Passive Scan selected, this will simply report findings" -ForegroundColor green
 #Loop through each resource group
$rsgs = Get-AzResourceGroup
$foundSA = 0
$foundVN = 0
$global:DiscoveredSAs=@()
$global:DiscoveredVNs=@()
            foreach ($rsg in $rsgs)
                    {
Write-Host "[PASSIVE] Scanning the current Azure Resource Group named ..... < $($rsg.ResourceGroupName) > for any Storage Accounts where the firewall is set to (ALLOW) and for any Virtual Networks where the Microsoft.Storage Service Endpoint is missing" -ForegroundColor green
Write-Host ""
Write-Host "[PASSIVE] Scanning for Storage Accounts.... That meet our requirements..." -ForegroundColor Blue
$azureSAs = Get-AzStorageAccount -ResourceGroupName $rsg.ResourceGroupName | where-object {$_.NetworkRuleSet.DefaultAction -eq "Allow"}
                        foreach ($azureSA in $azureSAs)
                                {
                                    If ($azureSA)  
                                            {
                                        Write-Host "[PASSIVE] Storage Account found named: $($azureSA.StorageAccountName)" -ForegroundColor yellow
                                        Write-Host "[PASSIVE] Firewall Status: $($azureSA.NetworkRuleSet.DefaultAction)" -ForegroundColor yellow
                                        $foundSA++
                                        $global:DiscoveredSAs += $azureSA
                                            }
                                                else{
                                                        Write-Host "[PASSIVE] No Azure Storage Account found that matched our needs within <$($rsg.ResourceGroupName) >" -foregroundcolor green
                                                        } #End If statement for AzureSA
                                    } #End foreach loop AzureSA

                                    If($azureSAs)
                                    {
        ######################STARTING VNET SEARCH FOR WHEN A RESOURCE GROUP CONTAINS A STORAGE ACCOUNT ##################################
                                                    Write-Host "[PASSIVE] Scanning for Virtual Networks.... That meet our requirements..." -ForegroundColor Blue
                                                    $vnets = Get-AzVirtualNetwork -ResourceGroupName $rsg.ResourceGroupName
                                                    foreach ($vnet in $vnets) 
                                                        {
                                                            If ($vnet.Subnets.ServiceEndpoints.Service -notcontains "Microsoft.Storage") 
                                                                     {
                                                                        Write-Host "[PASSIVE] This virtual network does NOT have the service endpoint listed as REQUIRED" $vnet.name -ForegroundColor yellow
                                                                        Write-Host "[PASSIVE] Here are the Service Endpoints discovered for this vnet's subnets:" -ForegroundColor blue
                                                                        $vnet.Subnets.ServiceEndpoints.Service
                                                                        $foundVN++
                                                                        $global:DiscoveredVNs += $vnet
                                                                     } #End if statement vnet
                                                                        else {
                                                                                Write-Host "[PASSIVE] No Azure Virtual Networks found that matched our needs within <$($rsg.ResourceGroupName) > where storage account < $($azureSA.StorageAccountName)> " -foregroundcolor green
                                                                                } #end If statement else
                                                            } #End foreach loop vnet
######################ENDING VNET SEARCH FOR WHEN A RESOURCE GROUP CONTAINS A STORAGE ACCOUNT ##################################
                                     } # ends Azure SAS If
                                            else {
                                                            Write-Host "[PASSIVE] No Storage Account was discovered" -ForegroundColor red
                                                    }
                        }#End RSG Foreach Loop
Write-Host "[PASSIVE] Passive Scanning Complete...." -ForegroundColor Blue
Write-Host "[PASSIVE] Building Report....Standby" -ForegroundColor Blue
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

                        } #End Passive P Loop

                else{
                        Write-Host  "Incorrect Option Specified" -ForegroundColor red
                        }
            } Until ($passive -match "P" -or $passive -match "E") #End Do Loop
}#end Function
Start-AzSAFWConfig

[System.Collections.ArrayList]$filtered = @()
foreach($vnetrule in $vnetsubrules)
{
    If ($vnetrule.Value -match "Test-RSG")
    {
    $filtered = $filtered += $vnetrule
    }
}
$filtered
