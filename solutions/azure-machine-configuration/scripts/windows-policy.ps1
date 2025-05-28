$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://$STORAGE_ACCOUNT_NAME.blob.core.windows.net/windows-machine-configuration/WindowsFeatures.zip?$SAS_WIN_POLICY'
  DisplayName   = 'Enable Windows Features - Web Server'
  Description   = 'Enable Windows Features - Web Server'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Windows'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
}

New-GuestConfigurationPolicy @PolicyConfig