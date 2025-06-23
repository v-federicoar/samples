$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://xx.blob.core.windows.net/azuremachineconfiguration/WindowsFeatures.zip?sas'
  DisplayName   = 'Far - Windows Feature Policy - Test - TBD'
  Description   = 'Far - Windows Feature Policy - Test - TBD'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Windows'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
}

New-GuestConfigurationPolicy @PolicyConfig