### Finding Resources Groups ###
$rsgs = Get-AzResourceGroup
If($rsgs -eq $null) { Write-Warning ('No Azure Resource Groups found, script ending.') EXIT } else { Write-Warning ('Azure Resource Groups found, continuing.') }
 
### Finding vNets within the found Resource Groups ###
foreach ($rsg in $rsgs){
        Write-Warning ('Starting vNet lookups within ' +  $rsg.ResourceGroupName)
$vnet = Get-AzVirtualNetwork     -ResourceGroupName $rsg.ResourceGroupName
If ($vnet -eq $null) {
Write-Warning ('No Azure Virtual Networks were found in ' + $rsg.ResourceGroupName)
                      }
else {
Write-Warning ("Azure Virtual Network found " + "'" + $vnets.Name + "'" + " in " + "'" + $vnets.ResourceGroupName + "'")
Write-Warning ("Begin Policy creation")
$policyName = "Block AZ Storage Account Public Access in $($rsg.ResourceGroupName)"
$policyDescription = "Force Azure Storage Accounts in $($rsg.ResourceGroupName) to block public access and only allow $($vnet.Name)"
$subnetRSSId = $vnet.Subnets.Id
$policy = @"
{
    "properties": {
     "displayName": "$policyName",
     "policyType": "Custom",
     "mode": "All",
     "description": "$policyDescription",
     "metadata": {
            "category": "Storage"
     },
     "parameters": {
      "effect": {
       "type": "String",
       "metadata": {
        "displayName": "Effect",
        "description": "Enable or disable the execution of the policy"
       },
       "allowedValues": [
        "DeployIfNotExists",
        "Disabled"
       ],
       "defaultValue": "DeployIfNotExists"
      },
      "subnetRssId": {
       "type": "String",
       "metadata": {
        "displayName": "Azure Subnet Resource Id",
        "description": "The subnet resource id to add to access rules"
       }
      }
     },
     "policyRule": {
      "if": {
       "allOf": [
        {
         "field": "type",
         "equals": "Microsoft.Storage/storageAccounts"
        },
        {
         "field": "Microsoft.Storage/storageAccounts/networkAcls.defaultAction",
         "notEquals": "Deny"
        }
       ]
      },
      "then": {
       "effect": "[parameters('effect')]",
       "details": {
        "type": "Microsoft.Storage/storageAccounts",
        "roleDefinitionIds": [
         "/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c"
        ],
        "existenceCondition": {
         "field": "Microsoft.Storage/storageAccounts/networkAcls.defaultAction",
         "equals": "Deny"
        },
        "deployment": {
         "properties": {
          "mode": "incremental",
          "template": {
           "`$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
           "contentVersion": "1.0.0.0",
           "parameters": {
            "name": {
             "type": "string"
            },
            "sku": {
             "type": "string"
            },
            "kind": {
             "type": "string"
            },
            "location": {
             "type": "string"
            },
            "subnetRssId": {
             "type": "string"
            }
           },
           "resources": [
            {
             "name": "[parameters('name')]",
             "type": "Microsoft.Storage/storageAccounts",
             "apiVersion": "2019-06-01",
             "location": "[parameters('location')]",
             "properties": {
              "networkAcls": {
               "bypass": "AzureServices",
               "virtualNetworkRules": [
                {
                 "id": "[parameters('subnetRssId')]",
                 "action": "Allow"
                }
               ],
               "ipRules": [],
               "defaultAction": "Deny"
              }
             },
             "dependsOn": [],
             "sku": {
              "name": "[parameters('sku')]"
             },
             "kind": "[parameters('kind')]"
            }
           ]
          },
          "parameters": {
           "name": {
            "value": "[field('name')]"
           },
           "sku": {
            "value": "[field('Microsoft.Storage/storageAccounts/sku.name')]"
           },
           "location": {
            "value": "[field('location')]"
           },
           "kind": {
            "value": "[field('kind')]"
           },
           "subnetRssId": {
            "value": "[parameters('subnetRssId')]"
           }
          }
         }
        }
       }
      }
     }
    },
    "id": "/subscriptions/ab2a5b44-4103-4da4-ba84-dd64b13cd1ec/providers/Microsoft.Authorization/policyDefinitions/cde5236e-640e-4f98-ab4e-bc6193347a5f",
    "type": "Microsoft.Authorization/policyDefinitions",
    "name": "cde5236e-640e-4f98-ab4e-bc6193347a5f"
   }
"@
 
New-AzPolicyDefinition -name $policyName -Metadata '{"category":"Storage"}' -Policy $policy -Description $policyDescription
$azurePolicy = Get-AzPolicyDefinition -name $policyName
$allowedSubnets = @{'subnetRssId'= ($subnetRSSId)}
$allowedSubnets
New-AzPolicyAssignment -Name $policyName `
  -DisplayName $policyDescription `
  -PolicyDefinition $azurePolicy -PolicyParameterObject $allowedSubnets -AssignIdentity -Location 'USGov Virginia' -Scope $rsg.ResourceID
                      }
                    }
