$myguid = [guid]::NewGuid()
$PolicyConfig      = @{
  PolicyId      = $myguid 
  ContentUri    = 'https://xx.blob.core.windows.net/azuremachineconfiguration/NginxInstall.zip?sas'
  DisplayName   = 'Far -NGINX - Linux - TBD'
  Description   = 'Far -NGINX - Linux - TBD'
  Path          = './policies/auditIfNotExists'
  Platform      = 'Linux'
  PolicyVersion = '1.0.0'
  Mode          = 'ApplyAndAutoCorrect'
}

New-GuestConfigurationPolicy @PolicyConfig