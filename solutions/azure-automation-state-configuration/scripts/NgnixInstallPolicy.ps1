$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://stvaletblobs43efoky.blob.core.windows.net/windows-machine-configuration/NginxInstall.zip?sasToken'
  DisplayName   = 'FAR -NGINX - Test - TBD'
  Description   = 'FAR -NGINX - Test - TBD'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Linux'
  PolicyVersion = '2.0.0'
  Mode          = 'ApplyAndAutoCorrect'
}

New-GuestConfigurationPolicy @PolicyConfig