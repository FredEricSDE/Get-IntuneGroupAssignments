
<#

.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.

#>

####################################################

Function Get-SoftwareUpdatePolicy()
{

    <#
    .SYNOPSIS
    This function is used to get Software Update policies from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any Software Update policies
    .EXAMPLE
    Get-SoftwareUpdatePolicy -Windows10
    Returns Windows 10 Software Update policies configured in Intune
    .EXAMPLE
    Get-SoftwareUpdatePolicy -iOS
    Returns iOS update policies configured in Intune
    .NOTES
    NAME: Get-SoftwareUpdatePolicy
    #>

    [cmdletbinding()]

    param
    (
        [switch]$Windows10,
        [switch]$iOS
    )

    $graphApiVersion = "Beta"

    try 
    {
        $Count_Params = 0

        if($iOS.IsPresent){ $Count_Params++ }
        if($Windows10.IsPresent){ $Count_Params++ }

        if($Count_Params -gt 1)
        {
            write-host "Multiple parameters set, specify a single parameter -iOS or -Windows10 against the function" -f Red
        }

        elseif($Count_Params -eq 0)
        {
            Write-Host "Parameter -iOS or -Windows10 required against the function..." -ForegroundColor Red
            Write-Host
            break
        }

        elseif($Windows10)
        {
            $Resource = "deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.windowsUpdateForBusinessConfiguration')&`$expand=groupAssignments"

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value
        }

        elseif($iOS)
        {
            $Resource = "deviceManagement/deviceConfigurations?`$filter=isof('microsoft.graph.iosUpdateConfiguration')&`$expand=groupAssignments"

            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
        }
    }

    catch 
    {
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

Function Get-SoftwareUpdateAssignmentGroups()
{
    $WSUPs = Get-SoftwareUpdatePolicy -Windows10

    $SoftwareUpdateAssignment = @{}

    if($WSUPs)
    {
        foreach($WSUP in $WSUPs)
        {
            $GroupDisplayName = @()

            $TargetGroupIds = $WSUP.groupAssignments.targetGroupId

            if($TargetGroupIds)
            {
                foreach($group in $TargetGroupIds)
                {
                    $GroupDisplayName += (Get-AADGroup -id $group).displayName
                }

                $SoftwareUpdateAssignment.Add($WSUP.displayName,$GroupDisplayName)
                $AllAssignments.Add($WSUP.displayName,$GroupDisplayName)
            }
            
            $GroupDisplayName = $null
        }
    }

    ####################################################

    $ISUPs = Get-SoftwareUpdatePolicy -iOS

    if($ISUPs)
    {
        foreach($ISUP in $ISUPs)
        {
            $GroupDisplayName = @()
            
            $TargetGroupIds = $ISUP.groupAssignments.targetGroupId

            if($TargetGroupIds)
            {
                foreach($group in $TargetGroupIds)
                {
                    $GroupDisplayName += (Get-AADGroup -id $group).displayName
                }

                $SoftwareUpdateAssignment.Add($ISUP.displayName,$GroupDisplayName)
                $AllAssignments.Add($ISUP.displayName,$GroupDisplayName)
            }

            $GroupDisplayName = $null
        }
    }

    $SoftwareUpdateAssignment.GetEnumerator() | Sort -Property Name | Format-Table -AutoSize
}