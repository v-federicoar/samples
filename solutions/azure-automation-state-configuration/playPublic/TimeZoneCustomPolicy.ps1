


$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://stvaletblobs43efoky.blob.core.windows.net/windows-machine-configuration/TimeZoneCustom.zip?se=2025-06-02T17%3A28Z&sp=r&sv=2022-11-02&sr=b&skoid=4d18c03a-7ebc-454d-ac10-88fec62b352f&sktid=888d76fa-54b2-4ced-8ee5-aac1585adee7&skt=2025-05-26T17%3A28%3A04Z&ske=2025-06-02T17%3A28%3A00Z&sks=b&skv=2022-11-02&sig=9CUGv0d9NZIuJ%2FgMQ%2BAvN2mA4fDP5fKRM2R1WDIB5TI%3D'
  DisplayName   = 'Far - Time Zone Custom Policy - Test - TBD'
  Description   = 'Far - Time Zone Custom Policy - Test - TBD'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Windows'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
}

New-GuestConfigurationPolicy @PolicyConfig