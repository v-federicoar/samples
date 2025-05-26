targetScope = 'resourceGroup'

/*** PARAMETERS ***/

@description('Azure Virtual Machines, and supporting services (Automation State Configuration) region. This defaults to the resource group\'s location for higher reliability.')
param location string = resourceGroup().location

@description('The admin user name for both the Windows and Linux virtual machines.')
param adminUserName string = 'admin'

@secure()
@description('The admin password for both the Windows and Linux virtual machines.')
param adminPassword string

// @description('The email address configured in the Action Group for receiving non-compliance notifications.')
// param emailAddress string

@description('The number of Azure Windows VMs to be deployed as web servers, configured via Desired State Configuration to install IIS.')
@minValue(0)
param windowsVMCount int = 1

@description('The number of Azure Linux VMs to be deployed as web servers, configured via Desired State Configuration to install NGINX.')
@minValue(0)
param linuxVMCount int = 1

@description('The Azure VM size. Defaults to an optimally balanced for general purpose, providing sufficient performance for deploying IIS on Windows and NGINX on Linux in testing environments.')
param vmSize string = 'Standard_A4_v2'

@description('Name for the storage account where the DCS configuration files are stored. This is used by the DSC extension to download the configuration files.')
param storageAccountName string

//param windowsDSCZipHash string

@description('The DSC configuration object containing a reference to the script that defines the desired state for Windows VMs. By default, it points to a PowerShell script that installs IIS for testing purposes as desired state of the system.')
param windowsConfiguration object = {
  name: 'windowsfeatures'
  description: 'A configuration for installing IIS.'
  script: 'https://raw.githubusercontent.com/mspnp/samples/main/solutions/azure-automation-state-configuration/scripts/windows-config.ps1'
}

@description('The DSC configuration object containing a reference to the script that defines the desired state for Linux VMs. By default, it points to a PowerShell script that installs NGINX for testing purposes as desired state of the system.')
param linuxConfiguration object = {
  name: 'linuxpackage'
  description: 'A configuration for installing Nginx.'
  script: 'https://raw.githubusercontent.com/mspnp/samples/main/solutions/azure-automation-state-configuration/scripts/linux-config.ps1'
}

/*** VARIABLES ***/

var logAnalyticsName = 'log-${uniqueString(resourceGroup().id)}-${location}'
var alertQuery = 'AzureDiagnostics\n| where Category == "DscNodeStatus"\n| where ResultType == "Failed"'
var windowsVMName = 'vm-win-${location}'
var linuxVMname = 'vm-linux-${location}'

/*** RESOURCES ***/


@description('Built-in Azure RBAC role that is applied to a Storage account to grant "Storage Blob Data Contributor" privileges. Used by the managed identity of the valet key Azure Function as for being able to delegate permissions to create blobs.')
resource storageBlobDataReaderRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
  scope: subscription()
}

resource contributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
  scope: subscription()
}

@description('Built-in Azure RBAC role that is applied to a Storage account to grant "Storage Blob Data Contributor" privileges. Used by the managed identity of the valet key Azure Function as for being able to delegate permissions to create blobs.')
resource guestConfigurationResourceContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: '088ab73d-1256-47ae-bea9-9de8e7131f31'
  scope: subscription()
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' = {
  name: 'identity-${location}'
  location: location
}

resource contributorRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userAssignedIdentity.id, 'contributor-role')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: contributorRole.id
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource guestConfigRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userAssignedIdentity.id, 'guest-config-role')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: guestConfigurationResourceContributorRole.id
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource userAssignedIdentityPolicy 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' = {
  name: 'id-policy-${location}'
  location: location
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: storageAccountName
}

@description('This Log Analytics workspace stores logs from the regional automation account and the virtual network.')
resource la 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    features: {
      searchVersion: 1
    }
  }
  @description('The Log Analytics workspace saved search to monitor Virtual Machines with Non-Compliant DSC status.')
  resource la_savedSearches 'savedSearches' = {
    name: '${la.name}-savedSearches'
    properties: {
      category: 'event'
      displayName: 'Non Compliant DSC Node'
      query: alertQuery
      version: 2
    }
  }
}

resource storageBlobDataReaderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userAssignedIdentity.id, 'storageBlobDataReaderRole')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: storageBlobDataReaderRole.id
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource storageBlobDataReaderRoleAssignmentPolicy 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(userAssignedIdentityPolicy.id, 'storageBlobDataReaderRole')
  scope: resourceGroup()
  properties: {
    roleDefinitionId: storageBlobDataReaderRole.id
    principalId: userAssignedIdentityPolicy.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// @description('The Log Analytics workspace scheduled query rule that trigger alerts based on Virtual Machines with Non-Compliant DSC status.')
// resource la_nonCompliantDsc 'microsoft.insights/scheduledqueryrules@2024-01-01-preview' = {
//   name: 'la-nonCompliantDsc'
//   location: location
//   properties: {
//     severity: 3
//     enabled: true
//     evaluationFrequency: 'PT5M'
//     scopes: [
//       la.id
//     ]
//     windowSize: 'PT5M'
//     criteria: {
//       allOf: [
//         {
//           query: alertQuery
//           timeAggregation: 'Count'
//           operator: 'GreaterThan'
//           threshold: 0
//           failingPeriods: {
//             numberOfEvaluationPeriods: 1
//             minFailingPeriodsToAlert: 1
//           }
//         }
//       ]
//     }
//     actions: {
//       actionGroups: [
//         ag_email.id
//       ]
//     }
//   }
// }

// @description('The Action Group responsible for sending email notifications when Non-Compliant DSC alerts are triggered.')
// resource ag_email 'microsoft.insights/actionGroups@2024-10-01-preview' = {
//   name: 'ag-email'
//   location: 'Global'
//   properties: {
//     groupShortName: 'emailService'
//     enabled: true
//     emailReceivers: [
//       {
//         name: 'emailAction'
//         emailAddress: emailAddress
//         useCommonAlertSchema: false
//       }
//     ]
//   }
// }

// @description('Automation Account creation')
// module automationAccount 'modules/automationAccounts.bicep' = {
//   params:{
//     logAnalyticsName:la.name
//     linuxConfiguration: linuxConfiguration
//     windowsConfiguration: windowsConfiguration
//     location: location
//   }
// }

@description('Network creation')
module network './modules/network.bicep' = {
  params: {
    logAnalyticsName: la.name
    location: location
  }
}

@description('Create Network Interfaces and Public Ips for Windows VMS')
module windowsVMNetworkResources './modules/vmNetworkResources.bicep' = {
  params: {
    subnetId: network.outputs.subnetId
    location: location
    vMCount: windowsVMCount
    identifier: 'windows'
  }
}

@description('The Windows VMs managed by DSC. By default, these virtual machines are configured to enforce the desired state using the DSC VM extension, ensuring consistency and compliance.')
resource vm_windows 'Microsoft.Compute/virtualMachines@2024-11-01' = [
  for i in range(0, windowsVMCount): {
    name: '${windowsVMName}${i}'
    location: location
    identity: {
      // It is required by the Guest Configuration extension.
      type: 'SystemAssigned'
    }
    properties: {
      hardwareProfile: {
        vmSize: vmSize
      }
      osProfile: {
        computerName: '${windowsVMName}${i}'
        adminUsername: adminUserName
        adminPassword: adminPassword
        windowsConfiguration: {
          enableAutomaticUpdates: true
          patchSettings: {
            //Machines should be configured to periodically check for missing system updates
            assessmentMode: 'AutomaticByPlatform'
            patchMode: 'AutomaticByPlatform'
          }
        }
      }
      storageProfile: {
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2022-Datacenter'
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
        }
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: windowsVMNetworkResources.outputs.nics[i].resourceId
          }
        ]
      }
      securityProfile: {
        // We recommend enabling encryption at host for virtual machines and virtual machine scale sets to harden security.
        encryptionAtHost: false
      }
    }
  }
]

@description('Windows VM guest extension')
resource vm_guestConfigExtensionWindows 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = [
  for i in range(0, windowsVMCount): {
    parent: vm_windows[i]
    name: 'AzurePolicyforWindows${vm_windows[i].name}'
    location: location
    properties: {
      publisher: 'Microsoft.GuestConfiguration'
      type: 'ConfigurationforWindows'
      typeHandlerVersion: '1.29'
      autoUpgradeMinorVersion: true
      enableAutomaticUpgrade: true
      settings: {}
      protectedSettings: {}
    }
  }
 ]


resource blobReadStorage 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for i in range(0, windowsVMCount): {
    name: guid(storageAccount.id, storageBlobDataReaderRole.id, vm_windows[i].id)
    scope: storageAccount
    properties: {
      principalId: vm_windows[i].identity.principalId
      roleDefinitionId: storageBlobDataReaderRole.id
      principalType: 'ServicePrincipal' // 'ServicePrincipal' if this was a managed identity
      description: 'Allows this Microsoft Entra VM to read blobs in this storage container.'
    }
  }
]

@description('Create Network Interfaces and Public Ips for Linux VMS')
module linuxVMNetworkResources './modules/vmNetworkResources.bicep' = {
  params: {
    subnetId: network.outputs.subnetId
    location: location
    vMCount: linuxVMCount
    identifier: 'linux'
  }
}

@description('The Linux VMs managed by DSC. By default, these virtual machines are configured to enforce the desired state using the DSC VM extension, ensuring consistency and compliance.')
resource vm_linux 'Microsoft.Compute/virtualMachines@2024-11-01' = [
  for i in range(0, linuxVMCount): {
    name: '${linuxVMname}${i}'
    location: location
    identity: {
      // It is required by the Guest Configuration extension.
      type: 'SystemAssigned'
    }
    properties: {
      hardwareProfile: {
        vmSize: vmSize
      }
      osProfile: {
        computerName: '${linuxVMname}${i}'
        adminUsername: adminUserName
        adminPassword: adminPassword
        linuxConfiguration: {
          patchSettings: {
            //Machines should be configured to periodically check for missing system updates
            assessmentMode: 'AutomaticByPlatform'
            patchMode: 'AutomaticByPlatform '
          }
          disablePasswordAuthentication: false
          provisionVMAgent: true
        }
      }
      storageProfile: {
        imageReference: {
          publisher: 'Canonical'
          offer: 'UbuntuServer'
          sku: '18.04-LTS'
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
        }
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: linuxVMNetworkResources.outputs.nics[i].resourceId
          }
        ]
      }
      securityProfile: {
        // We recommend enabling encryption at host for virtual machines and virtual machine scale sets to harden security.
        encryptionAtHost: false
      }
    }
  }
]

@description('Linux VM guest extension')
resource vm_guestConfigExtensionLinux 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = [
  for i in range(0, linuxVMCount): {
    parent: vm_linux[i]
    name: 'Microsoft.AzurePolicyforLinux${vm_linux[i].name}'
    location: location
    properties: {
      publisher: 'Microsoft.GuestConfiguration'
      type: 'ConfigurationForLinux'
      typeHandlerVersion: '1.0'
      autoUpgradeMinorVersion: true
      enableAutomaticUpgrade: true
      settings: {}
      protectedSettings: {}
    }
  }
]

output userAssignedIdentityId string = userAssignedIdentity.id 
output userAssignedIdentityPolicyId string = userAssignedIdentityPolicy.id
