---
page_type: sample
languages:
- azurecli
products:
- azure
description: These Bicep template samples deploy Azure Machine Configuration scenario, and it will compile PowerShell Desired State Configuration scripts. Then, the Bicep template deploys 1 to many virtual machines (Windows and Linux), which then uses the compiled configurations to install a webserver on each of the virtual machines.
---

# Azure Machine Configuration

This sample deploys an [Azure Machine Configuration](https://learn.microsoft.com/azure/governance/machine-configuration/) scenario, and it will compile PowerShell Desired State Configuration scripts. Then, the Bicep template deploys 1 to many virtual machines (Windows and Linux), which then uses the compiled configurations to install a webserver on each of the virtual machines.  

Azure Machine Configuration enables you to audit and enforce configuration settings on both Azure and hybrid (Arc-enabled) machines using code. It leverages PowerShell Desired State Configuration (DSC) to define the desired state of a system and ensures compliance through Azure Policy. It supports custom configuration packages and provides detailed compliance reporting through Azure Resource Graph.  

The main difference between Azure Machine Configuration and Azure Automation State Configuration lies in their architecture and integration. Azure Automation State Configuration relies on Azure Automation accounts and DSC pull servers. In contrast, Azure Machine Configuration is fully integrated into Azure Resource Manager and Azure Policy, eliminating the need for separate automation infrastructure. It supports direct assignment of configurations, multiple configurations per machine, and more granular remediation controls. 

## Deploy bases

  Before you begin, ensure you have the Azure Command-Line Interface (CLI) installed.

  Clone this repository:

  ```bash
    git clone https://github.com/mspnp/samples.git
    cd ./samples/solutions/azure-machine-configuration
  ```

### Create a Resource Group

```bash
  az group create --name rg-machine-configuration-eastus --location eastus
```

### Deploy Storage Account and User-Assigned Managed Identities
To deploy a custom guest configuration policy in Azure, you’ll need a Storage Account to host the .zip package containing the compiled .mof file, metadata, and any required DSC resources. This storage location enables Azure Policy to access and distribute the configuration package to target machines.  

Azure Storage access is managed via RBAC. The provided script assigns the necessary roles to the current user to allow file uploads.  

The Bicep template also deploys two User-Assigned Managed Identities:

* Policy VM Identity: Assigned to the virtual machine and policy. It requires Storage Blob Data Reader permissions to download the policy package from the VM.
* Policy Assignment Identity: Used during policy assignment. It must have Contributor and Guest Configuration Resource Contributor roles. We use Resource Group scope.

```bash
  CURRENT_USER_OBJECT_ID=$(az ad signed-in-user show -o tsv --query id)
  STORAGE_ACCOUNT_NAME="stpolices$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | fold -w 7 | head -n 1)"
  az deployment group create --resource-group rg-machine-configuration-eastus --template-file ./bicep/guestConfigInfraSetup.bicep  -p storageAccountName=$STORAGE_ACCOUNT_NAME principalId=$CURRENT_USER_OBJECT_ID

  POLICY_DOWNLOAD_USER_ASSIGNED_IDENTITY=$(az deployment group show --resource-group rg-machine-configuration-eastus --name guestConfigInfraSetup --query "properties.outputs.policyDownloadUserAssignedIdentityId.value" --output tsv)
```

## Azure Policy Creation
Custom policies using Desired State Configuration (DSC) in Azure are built on the **Guest Configuration** framework. This framework enables administrators to define and enforce configuration baselines across both Windows and Linux machines.  

These policies are authored using PowerShell DSC resources and compiled into MOF (Managed Object Format) files. The typical workflow includes:  

1. Creating a DSC resource.
2. Defining the configuration.
3. Compiling it into a MOF file.
4. Packaging the output into a .zip file.
5. Publishing and assigning the package as an Azure Policy.  

Once assigned, **Azure Policy** evaluates the configuration on target machines and reports compliance status.  

### Prerequisites

To author and deploy custom guest configuration policies, ensure the following tools and modules are installed:

* **PowerShell 7** – Required for authoring and compiling DSC configurations.
* **PSDscResources** – A powershell module containing commonly used DSC resources.
* **GuestConfiguration** – A powershell module which provides cmdlets like New-GuestConfigurationPolicy and Get-GuestConfigurationPackageComplianceStatus to manage guest configuration packages and policies.
* **Az.Resources** – Required for commands such as New-AzPolicyDefinition and New-AzPolicyAssignment.
* **Az.Accounts** – Used for authentication and context management. Use Connect-AzAccount and Set-AzContext to authenticate and select the appropriate subscription.
* **Nxtools** – A powershell module used to compile Linux-based DSC scripts. It is an open-source module to help make managing Linux systems easier for PowerShell users. The module helps in managing common tasks such as: Managing users and groups,Performing file system operations, Managing services, Performing archive operations,Managing packages. The module includes class-based DSC resources for Linux and built-in machine configuration packages.

```powershell
  # Navigate to the Scripts Directory
  cd scripts
```

### Create MOF Files

This step involves generating **MOF (Managed Object Format)** files from PowerShell DSC scripts for both Linux and Windows environments.  

A MOF file is the compiled output of a PowerShell Desired State Configuration (DSC) script. It defines the desired state of a system in a standardized format that can be interpreted by the Local Configuration Manager (LCM) on a target machine. The LCM uses this file to enforce or audit system settings.  

You can generate the MOF files by running the following scripts:  

```powershell
  ./linux-config.ps1   # It will generate ./NginxInstall/localhost.mof
  ./windows-config.ps1 # It will generate ./windowsfeatures/localhost.mof
```
Each script compiles its respective configuration and outputs the MOF file into a subdirectory named after the configuration.  

### Package Configuration 
Once the MOF files are generated, the next step is to package them into a format that Azure Policy can use.  

The New-GuestConfigurationPackage cmdlet is used to create a Guest Configuration package from a compiled .mof file. This package includes:  

* The .mof file (defining the desired system state),
* Metadata,
* Any required DSC resources.

The resulting .zip file is ready to be published and assigned as a custom policy in Azure. Once assigned, Azure Policy uses this package to audit or enforce configuration compliance on Azure or Arc-enabled machines.  

Run the following scripts to generate the packages:  

```powershell
  ./linux-package.ps1   # It will generate ./NginxInstall.zip
  ./windows-package.ps1 # It will generate ./WindowsFeatures.zip
```
Each script packages the corresponding MOF and resources into a ZIP file, preparing it for policy definition and assignment.  

### Upload Configuration to Azure Storage
Once the configuration packages (.zip files) are created, they must be uploaded to an Azure Storage Account. These packages will be referenced by Azure Policy during assignment and evaluation.  

```bash
 az storage blob upload --account-name $STORAGE_ACCOUNT_NAME --container-name windowsmachineconfiguration --file ./scripts/NginxInstall.zip --auth-mode login  --overwrite

 az storage blob upload --account-name $STORAGE_ACCOUNT_NAME --container-name windowsmachineconfiguration --file ./scripts/WindowsFeatures.zip --auth-mode login  --overwrite
 
# After uploading, you can construct the URLs to reference these packages in your policy definitions:
URL_LX_CONTENT="https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/windowsmachineconfiguration/NginxInstall.zip"
echo $URL_LX_CONTENT

URL_WIN_CONTENT="https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/windowsmachineconfiguration/WindowsFeatures.zip"
echo $URL_WIN_CONTENT
```
### Generate Policies
On linux-policy.ps1, change the ContentUri for the content of $URL_LX_CONTENT and ManagedIdentityResourceId by $POLICY_DOWNLOAD_USER_ASSIGNED_IDENTITY  
On windows-policy.ps1, change the ContentUri for the content of $URL_WIN_CONTENT and ManagedIdentityResourceId by $POLICY_DOWNLOAD_USER_ASSIGNED_IDENTITY  

```powershell
   # Generate Policy Definition
  ./linux-policy.ps1   # It will generate the policy definition at .\policies\auditIfNotExists\NginxInstall_DeployIfNotExists.json
  ./windows-policy.ps1 # It will generate the policy definition at .\policies\auditIfNotExists\WindowsFeatures_DeployIfNotExists.json

  # Deploy Policies
  New-AzPolicyDefinition -Name 'nginx-install' -Policy ".\policies\auditIfNotExists\NginxInstall_DeployIfNotExists.json"
  New-AzPolicyDefinition -Name 'IIS-install' -Policy ".\policies\auditIfNotExists\WindowsFeatures_DeployIfNotExists.json"
```

### Assign Policies
Assign the policy to work aganst any virtual machine in our resoruce group. 

The Guest Configuration Resource Contributor role is needed to be assigned on the User Assigned Identitty, it allows the identity to:
* Write guest configuration assignments.  
* Read and report compliance data from virtual machines.  
* Deploy the Guest Configuration extension if needed.  

Contributor Role (optional but common): Grants broad permissions including the ability to create and manage resources, which may be necessary depending on what the policy does.  

This is critical because Azure Policy uses this identity to enforce and monitor the guest configuration on target machines. Without this role, the policy assignment may succeed, but the guest configuration won't be applied or reported correctly.

```powershell
$ResourceGroup = Get-AzResourceGroup -Name rg-machine-configuration-eastus
$UserAssignedIdentity = Get-AzUserAssignedIdentity -ResourceGroupName rg-machine-configuration-eastus -Name 'identity-eastus'

$policyDefinitionNginxInstall = Get-AzPolicyDefinition -Name 'nginx-install'
New-AzPolicyAssignment -Name 'nginx-install' -DisplayName "nginx-install Assignment" -Scope $ResourceGroup.ResourceId  -PolicyDefinition $policyDefinitionNginxInstall -Location 'eastus' -IdentityType 'UserAssigned' -IdentityId $UserAssignedIdentity.Id

$policyDefinitionWin = Get-AzPolicyDefinition -Name 'IIS-install'
New-AzPolicyAssignment -Name 'IIS-install' -DisplayName "IIS-install Assignment" -Scope $ResourceGroup.ResourceId  -PolicyDefinition $policyDefinitionWin -Location 'eastus' -IdentityType 'UserAssigned' -IdentityId $UserAssignedIdentity.Id

# Go back to root folder
cd..
```

## Deploy sample

Run the following command to initiate the deployment. If you would like to adjust the number of virtual machines deployed, update the *windowsVMCount* and *linuxVMCount* values.  

To apply policies using Azure Machine Configuration, the virtual machine must have the Guest Configuration extension installed and be enabled with a system-assigned managed identity, which allows it to authenticate and interact securely with the configuration service to download and enforce policy assignments.  

To successfully download the Desired State Configuration (DSC), the virtual machine must be assigned the policy user-assigned managed identity that has the Storage Blob Data Reader role.

```bash
az deployment group create --resource-group rg-machine-configuration-eastus -f ./bicep/main.bicep -p policyUserAssignedIdentityId=$POLICY_USER_ASSIGNED_IDENTITY
```
## Check Policy download
The solution has Azure Bastion deployed. You can log in to the Azure VM and inspect the Guest Extension.

Here where are the [client Guest Configuration log](https://learn.microsoft.com/azure/governance/machine-configuration/overview#client-log-files) file for more details.  

Within the GuestConfig/Configuration folder, you should find the downloaded policies.   

## Monitoring 
Each virtual machine includes visibility into the Azure Policies applied to it, along with its current compliance status, enabling users to track and manage configuration adherence effectively.  

![Image of Azure Policies compliant on a VM as seen in the Azure portal.](./images/VMPolicies.png)  

It is possible view the general compliant situation on Policies  

![Image of Azure Policies compliant on Policy View as seen in the Azure portal.](./images/ComplianceFromPolicies.png)  

In this view is possible to see our Policies definition and assigments  

![Image of Azure Policies Definition.](./images/PolicyDefinition.png)   
![Image of Azure Policies Assigment.](./images/PolicyAssigment.png)  


It could take hours to detect the issue, remediate and be complaint. After that you could check using the VM public ip and call it in a browser.  

![Checking Compliant situation](./images/Checking.png)  


## Solution deployment parameters

| Parameter | Type | Description | Default |
|---|---|---|--|
| adminUserName | string | If deploying virtual machines, the admin user name. | admin-user |
| adminPassword | securestring | If deploying virtual machines, the admin password. | null |
| windowsVMCount | int | Number of Windows virtual machines to create in spoke network. | 1 |
| linuxVMCount | int | Number of Linux virtual machines to create in spoke network. | 1 |
| vmSize | string | Size for the Windows and Linux virtual machines. | Standard_A4_v2 |
| location | string | Deployment location. | resourceGroup().location |

## Clean Up

```bash
az group delete -n rg-machine-configuration-eastus  -y

az policy definition delete --name nginx-install

az policy definition delete --name IIS-install

```

## Microsoft Open Source Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).

Resources:

- [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)
- [Microsoft Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/)
- Contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with questions or concerns
