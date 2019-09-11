##################################################################################
#
# Intune Group Assignments
#
# Version v.0.1 
# Version v.0.1 
#
# 28.08.2019
#
# Get-IntuneGroupAssignments.ps1 - this file is the main file that combines all required
# functions as your central starting point.
#
# Execution:
#
# Example - .\Get-IntuneGroupAssignments.ps1 -Option All
# Example - .\Get-IntuneGroupAssignments.ps1 -Option DeviceConfigs
# Example - .\Get-IntuneGroupAssignments.ps1 -Option Apps
# Example - .\Get-IntuneGroupAssignments.ps1 -Option Compliance
# Example - .\Get-IntuneGroupAssignments.ps1 -Option SoftwareUpdates
#
##################################################################################

param(
        [String]$Option
    )

Import-Module .\Modules\GlobalFunctions.psm1 -Global
Import-Module .\Modules\Get-ApplicationAssignmentGroups.psm1 -Global
Import-Module .\Modules\Get-DeviceConfigurationAssignmentGroups.psm1 -Global
Import-Module .\Modules\Get-DeviceComplianceAssignmentGroups.psm1 -Global
Import-Module .\Modules\Get-SoftwareUpdateAssignmentGroups.psm1 -Global

#$Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size (512, 80)

Get-Login

switch($Option)
{
    "All"{Get-AllTargetGroups}
    "DeviceConfigs"{Get-DeviceConfigAssignmentGroups}
    "Apps"{Get-ApplicationAssignmentGroups}
    "Compliance"{Get-ComplianceAssignmentGroups}
    #"SoftwareUpdates"{Get-SoftwareUpdateAssignmentGroups}
}