


$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://xx.blob.core.windows.net/azuremachineconfiguration/TimeZoneCustom.zip?sas'
  DisplayName   = 'Far - Time Zone Custom Policy - Test - TBD'
  Description   = 'Far - Time Zone Custom Policy - Test - TBD'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Windows'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
}

New-GuestConfigurationPolicy @PolicyConfig