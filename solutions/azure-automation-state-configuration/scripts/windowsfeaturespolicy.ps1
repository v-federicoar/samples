$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://stvaletblobs43efoky.blob.core.windows.net/windows-machine-configuration/WindowsFeatures.zip?sasToken'
  DisplayName   = 'Far - Windows Feature Policy - Test - TBD'
  Description   = 'Far - Windows Feature Policy - Test - TBD'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Windows'
  PolicyVersion = '2.0.0'
  Mode          = 'ApplyAndAutoCorrect'
}

New-GuestConfigurationPolicy @PolicyConfig