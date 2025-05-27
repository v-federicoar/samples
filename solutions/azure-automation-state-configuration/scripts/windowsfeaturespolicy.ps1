$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://stvaletblobs2o1dbud.blob.core.windows.net/windows-machine-configuration/WindowsFeatures.zip?se=2025-06-03T13%3A56Z&sp=r&sv=2022-11-02&sr=b&skoid=4d18c03a-7ebc-454d-ac10-88fec62b352f&sktid=888d76fa-54b2-4ced-8ee5-aac1585adee7&skt=2025-05-27T13%3A56%3A11Z&ske=2025-06-03T13%3A56%3A00Z&sks=b&skv=2022-11-02&sig=mFBU19K3LofDlb5o0VlH1o%2Bt%2F%2FryYvrZjbrh1cqqxdQ%3D'
  DisplayName   = 'Far - Windows Feature Policy - Test - TBD'
  Description   = 'Far - Windows Feature Policy - Test - TBD'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Windows'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
}

New-GuestConfigurationPolicy @PolicyConfig