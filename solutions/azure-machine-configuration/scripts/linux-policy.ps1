$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://stpolices30vznnf.blob.core.windows.net/azuremachineconfiguration/NginxInstall.zip'
  DisplayName   = 'Enable Nginx on Linux VMs'
  Description   = 'Enable Nginx on Linux VMs'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Linux'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
  LocalContentPath = '.\NginxInstall.zip'
  ManagedIdentityResourceId = '/subscriptions/132f0217-59d1-4c16-8b39-c3d71b36e521/resourceGroups/rg-far1-machine-configuration-eastus/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-policy-download-eastuss'
}

New-GuestConfigurationPolicy @PolicyConfig -ExcludeArcMachines