$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/windows-machine-configuration/NginxInstall.zip?$SAS_LX_POLICY'
  DisplayName   = 'Enable Nginx on Linux VMs'
  Description   = 'Enable Nginx on Linux VMs'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Linux'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
}

New-GuestConfigurationPolicy @PolicyConfig