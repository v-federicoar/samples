


$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = "https://xx.blob.core.windows.net/windows-machine-configuration/TimeZoneCustom.zip"
  DisplayName   = 'Far - My audit policy - Test - TBD'
  Description   = 'Far - My audit policy - Test - TBD'
  Path          = './policies/auditIfNotExists'
  LocalContentPath = 'C:\repositories\samples\solutions\azure-automation-state-configuration\play\TimeZoneCustom.zip'
  Platform      = 'Windows'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
  ManagedIdentityResourceId = '/subscriptions/132f0217-59d1-4c16-8b39-c3d71b36e521/resourcegroups/rg-far-state-configuration-eastus/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-policy-eastus'
}

New-GuestConfigurationPolicy @PolicyConfig -ExcludeArcMachines