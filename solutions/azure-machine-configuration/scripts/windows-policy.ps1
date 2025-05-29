$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/windows-machine-configuration/WindowsFeatures.zip'
  DisplayName   = 'Enable Windows Features - Web Server'
  Description   = 'Enable Windows Features - Web Server'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Windows'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
  LocalContentPath = '.\WindowsFeatures.zip'
  ManagedIdentityResourceId = '/subscriptions/xxx/resourceGroups/rg-far-machine-configuration-eastus/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-policy-eastus'
}

New-GuestConfigurationPolicy @PolicyConfig -ExcludeArcMachines