Function Get-IntuneApplication()
{
    <#
    .SYNOPSIS
    This function is used to get applications from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any applications added
    .EXAMPLE
    Get-IntuneApplication
    Returns any applications configured in Intune
    .NOTES
    NAME: Get-IntuneApplication
    #>

    [cmdletbinding()]
        
    $graphApiVersion = "Beta"
    $Resource = "deviceAppManagement/mobileApps"
        
    try 
    {    
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value | ? { (!($_.'@odata.type').Contains("managed")) }
    }
    
    catch 
    {
        $ex = $_.Exception
        Write-Host "Request to $Uri failed with HTTP Status $([int]$ex.Response.StatusCode) $($ex.Response.StatusDescription)" -f Red
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

Function Get-ApplicationAssignment()
{
    <#
    .SYNOPSIS
    This function is used to get an application assignment from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets an application assignment
    .EXAMPLE
    Get-ApplicationAssignment
    Returns an Application Assignment configured in Intune
    .NOTES
    NAME: Get-ApplicationAssignment
    #>

    [cmdletbinding()]

    param
    (
        $ApplicationId
    )
        
    $graphApiVersion = "Beta"
    $Resource = "deviceAppManagement/mobileApps/$ApplicationId/?`$expand=categories,assignments"
        
    try 
    {    
        if(!$ApplicationId)
        {
            write-host "No Application Id specified, specify a valid Application Id" -f Red
            break
        }

        else 
        {
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get)
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

Function Get-ApplicationAssignmentGroups()
{
    <#
    .SYNOPSIS
    This function is used to get all Application Assignments and their targeted Groups from the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and gets any App that have assignments and their respective target groups
    .EXAMPLE
    Get-ApplicationAssignmentGroups
    .NOTES
    NAME: Get-ApplicationAssignmentGroups
    #>

    $AppList = Get-IntuneApplication $authToken

    $AppAssignment = $null
    $AppAssignment = @{}

    ForEach($App in $AppList)
    {
        $GroupDisplayName = @()

        if($App.isAssigned -eq $True)
        {
            $Assignment = Get-ApplicationAssignment -ApplicationId $App.ID

            $AppDisplayName = $App.displayName
            
            $AssignmentGroupIDs = $Assignment.assignments.target.groupId

            $AssignmentGroupIDs = $AssignmentGroupIDs
            
            if($Assignment.assignments.target.'@odata.type' -eq "#microsoft.graph.allLicensedUsersAssignmentTarget")
            {
                $GroupDisplayName += "All Users"
            }
            elseif($Assignment.assignments.target.'@odata.type' -eq "#microsoft.graph.allDevicesAssignmentTarget")
            {
                $GroupDisplayName += "All Devices"
            }
            else 
            {
                ForEach($GroupID in $AssignmentGroupIDs)
                {
                    if($GroupID -ne $null)
                    {
                        $GroupInfo = Get-AADGroup -id $GroupID
        
                        $GroupDisplayName += $GroupInfo.displayName
                    }
                }        
            }

            $GroupDisplayName = $GroupDisplayName | Sort | Unique
            
            $AppAssignment.Add($AppDisplayName, $GroupDisplayName)

            $AllAssignments.Add($AppDisplayName, $GroupDisplayName)
        }
    
        $GroupDisplayName = $null
    }

    $AppAssignment.GetEnumerator() | Sort -Property Name | Format-Table -AutoSize
}