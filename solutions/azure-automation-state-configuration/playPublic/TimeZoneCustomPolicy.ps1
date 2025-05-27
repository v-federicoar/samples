


$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://stvaletblobs2o1dbud.blob.core.windows.net/windows-machine-configuration/TimeZoneCustom.zip?se=2025-06-03T14%3A02Z&sp=r&sv=2022-11-02&sr=b&skoid=4d18c03a-7ebc-454d-ac10-88fec62b352f&sktid=888d76fa-54b2-4ced-8ee5-aac1585adee7&skt=2025-05-27T14%3A02%3A23Z&ske=2025-06-03T14%3A02%3A00Z&sks=b&skv=2022-11-02&sig=JmuugTv7njSCS6Adz09BBOk3Ubjnxl9G1mcTlm0OIkA%3D'
  DisplayName   = 'Far - Time Zone Custom Policy - Test - TBD'
  Description   = 'Far - Time Zone Custom Policy - Test - TBD'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Windows'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
}

New-GuestConfigurationPolicy @PolicyConfig