
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################

Function Get-DeviceConfigurationPolicy(){

<#
.SYNOPSIS
This function is used to get device configuration policies from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets any device configuration policies
.EXAMPLE
Get-DeviceConfigurationPolicy
Returns any device configuration policies configured in Intune
.NOTES
NAME: Get-DeviceConfigurationPolicy
#>

[cmdletbinding()]

param
(
    $name
)

$graphApiVersion = "v1.0"
$DCP_resource = "deviceManagement/deviceConfigurations"

    try {

        if($Name){

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | Where-Object { ($_.'displayName').contains("$Name") }

        }

        else {

        $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
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

Function Get-DeviceConfigurationPolicyAssignment(){

<#
.SYNOPSIS
This function is used to get device configuration policy assignment from the Graph API REST interface
.DESCRIPTION
The function connects to the Graph API Interface and gets a device configuration policy assignment
.EXAMPLE
Get-DeviceConfigurationPolicyAssignment $id guid
Returns any device configuration policy assignment configured in Intune
.NOTES
NAME: Get-DeviceConfigurationPolicyAssignment
#>

[cmdletbinding()]

param
(
    [Parameter(Mandatory=$true,HelpMessage="Enter id (guid) for the Device Configuration Policy you want to check assignment")]
    $id
)

$graphApiVersion = "v1.0"
$DCP_resource = "deviceManagement/deviceConfigurations"

    try {

    $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)/$id/Assignments"
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

Function Get-DeviceConfigAssignmentGroups()
{
    # Get all Device Configuration Policies

    $DCPs = Get-DeviceConfigurationPolicy

    # Create Hash-Table which will hold the results later on

    $DeviceConfigAssignment = @{}

    write-host

    # Check each Policy for a deployment

    foreach($DCP in $DCPs)
    {
        # Create an array that will hold all the Group names the policy is assigned to

        $GroupDisplayName = @()

        $id = $DCP.id

        # Get all the assignments for a policy

        $DCPA = Get-DeviceConfigurationPolicyAssignment -id $id

        # Check if there's an assignment. If not, we can skip to the next policy

        if($DCPA -ne $null)
        {
            $ConfigDisplayName = $DCP.displayName

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

            $DeviceConfigAssignment.Add($ConfigDisplayName, $GroupDisplayName)
            $AllAssignments.Add($ConfigDisplayName, $GroupDisplayName)
        }

        $GroupDisplayName = $null
    }

    $DeviceConfigAssignment.GetEnumerator() | Sort -Property Name | Format-Table -AutoSize
}