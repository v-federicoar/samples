
Configuration TimeZoneCustom
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName ComputerManagementDsc -Name TimeZone

    TimeZone TimeZoneConfig
    {
        TimeZone = 'Eastern Standard Time'
        IsSingleInstance = 'Yes'
    }   
}

TimeZoneCustom