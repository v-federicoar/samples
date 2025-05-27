$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://stvaletblobs2o1dbud.blob.core.windows.net/windows-machine-configuration/NginxInstall.zip?se=2025-06-03T13%3A53Z&sp=r&sv=2022-11-02&sr=b&skoid=4d18c03a-7ebc-454d-ac10-88fec62b352f&sktid=888d76fa-54b2-4ced-8ee5-aac1585adee7&skt=2025-05-27T13%3A53%3A46Z&ske=2025-06-03T13%3A53%3A00Z&sks=b&skv=2022-11-02&sig=ASckRKSDHDnfhbG3gRFKLEpDcGLPMsO8efq0EzsiziQ%3D'
  DisplayName   = 'Far -NGINX - Linux - TBD'
  Description   = 'Far -NGINX - Linux - TBD'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Linux'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
}

New-GuestConfigurationPolicy @PolicyConfig