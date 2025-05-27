# Create a package that will only audit compliance
$params = @{
    Name          = 'TimeZoneCustom'
    Configuration = './TimeZoneCustom/TimeZoneCustom.mof'
    Type          = 'AuditAndSet'
    Version       = '1.0.0'
    Force         = $true
}
New-GuestConfigurationPackage @params