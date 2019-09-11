
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################

Function Get-DeviceCompliancePolicy(){

<#
.SYNOPSIS
This function is used to get device compliance policies from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any device compliance policies
.EXAMPLE
Get-DeviceCompliancePolicy
Returns any device compliance policies configured in Intune
.EXAMPLE
Get-DeviceCompliancePolicy -Android
Returns any device compliance policies for Android configured in Intune
.EXAMPLE
Get-DeviceCompliancePolicy -iOS
Returns any device compliance policies for iOS configured in Intune
.NOTES
NAME: Get-DeviceCompliancePolicy
#>

[cmdletbinding()]

param
(
    $Name,
    [switch]$Android,
    [switch]$iOS,
    [switch]$Win10
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/deviceCompliancePolicies"

    try {

        $Count_Params = 0

        if($Android.IsPresent){ $Count_Params++ }
        if($iOS.IsPresent){ $Count_Params++ }
        if($Win10.IsPresent){ $Count_Params++ }
        if($Name.IsPresent){ $Count_Params++ }

        if($Count_Params -gt 1){

        write-host "Multiple parameters set, specify a single parameter -Android -iOS or -Win10 against the function" -f Red

        }

        elseif($Android){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains("android") }

        }

        elseif($iOS){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains("ios") }

        }

        elseif($Win10){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'@odata.type').contains("windows10CompliancePolicy") }

        }

        elseif($Name){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains("$Name") }

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

        }

    }

    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}

####################################################

Function Get-DeviceCompliancePolicyAssignment(){

<#
.SYNOPSIS
This function is used to get device compliance policy assignment from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets a device compliance policy assignment
.EXAMPLE
Get-DeviceCompliancePolicyAssignment -id $id
Returns any device compliance policy assignment configured in Intune
.NOTES
NAME: Get-DeviceCompliancePolicyAssignment
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true,HelpMessage="Enter id (guid) for the Device Compliance Policy you want to check assignment")]
    $id
)

$graphApiVersion = "Beta"
$DCP_resource = "deviceManagement/deviceCompliancePolicies"

    try {

    $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)/$id/assignments"
    (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value

    }

    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}

####################################################

Function Get-ComplianceAssignmentGroups()
{
    # Get all Device Compliance Policies

    $DCPs = Get-DeviceCompliancePolicy

    # Create Hash-Table which will hold the results later on

    $DeviceComplianceAssignment = @{}

    write-host

    # Check each Policy for a deployment

    foreach($DCP in $DCPs)
    {
        # Create an array that will hold all the Group names the policy is assigned to

        $GroupDisplayName = @()

        $id = $DCP.id

        # Get all the assignments for a policy

        $DCPA = Get-DeviceCompliancePolicyAssignment -id $id

        # Check if there's an assignment. If not, we can skip to the next policy

        if($DCPA -ne $null)
        {
            $ComplianceDisplayName = $DCP.displayName

            # Go through all the assignments and the groups or check if it's assigned to all users or all devices

            foreach($group in $DCPA)
            {
                if($group.id -ne $null)
                {
                    $result = switch($group.target.'@odata.type')
                    {
                        "#microsoft.graph.allLicensedUsersAssignmentTarget"{$GroupDisplayName += "All Users"}

                        "#microsoft.graph.allDevicesAssignmentTarget"{$GroupDisplayName += "All Devices"}
                    }

                    if($group.target.groupID -ne $null)
                    {
                        $GroupDisplayName += (Get-AADGroup -id $group.target.groupID).displayName
                    }
                }
            }

            # Add all the results to our Hash-Table

            $DeviceComplianceAssignment.Add($ComplianceDisplayName, $GroupDisplayName)
            $AllAssignments.Add($ComplianceDisplayName, $GroupDisplayName)
        }

        $GroupDisplayName = $null
    }

    $DeviceComplianceAssignment.GetEnumerator() | Sort -Property Name | Format-Table -AutoSize
}
