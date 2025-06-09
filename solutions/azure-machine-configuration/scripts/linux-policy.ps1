$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/windowsmachineconfiguration/NginxInstall.zip'
  DisplayName   = 'Enable Nginx on Linux VMs'
  Description   = 'Enable Nginx on Linux VMs'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Linux'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
  LocalContentPath = '.\NginxInstall.zip'
  ManagedIdentityResourceId = '/subscriptions/xxx/resourceGroups/rg-machine-configuration-eastus/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-policy-eastus'
}

New-GuestConfigurationPolicy @PolicyConfig -ExcludeArcMachines