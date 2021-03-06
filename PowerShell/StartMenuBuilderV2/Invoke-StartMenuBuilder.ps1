# - WARNING - WARNING - WARNING - WARNING - WARNING - WARNING
# Delete this reg hive to clear the Start Menu cache - This may delete all user customizations too! TEST BEFORE YOU IMPLEMENT!
# HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount\$de${a2d0f370-e3c9-4fc4-89e2-fd545269ca61}$start.tilegrid$windows.data.curatedtilecollection.tilecollection
#
# If issues occur with the regex (multiple items with same NAME), add a pound sign (#) to designate the AppID.
#     The regex will be split at the # sign, using the first part for NAME, and the second for APPID
#
[string]$fileStartMenu      = $env:windir + '\startmenulayout.xml'
[string]$columnsStartMenu   = '2'
[string]$groupName1         = 'Browsers'
[string[]]$groupOrder1      = '^Internet\sExplorer$', '^(Google\s)?Chrome$', '^Firefox$', '^Microsoft\sEdge$#^MSEdge$'
[string]$groupName2         = 'Office Suite'
[string[]]$groupOrder2      = '^Outlook(\s\d{4})?$', '^Word(\s\d{4})?$', '^Excel(\s\d{4})?$', '^PowerPoint(\s\d{4})?$', '^OneNote(\s\d{4})?$'
#[string[]]$groupOrder2NoSub = '^Outlook(\s\d{4})?$', '^Word(\s\d{4})?$', '^Excel(\s\d{4})?$', '^PowerPoint(\s\d{4})?$', '^OneNote(\s\d{4})?$', '^Access(\s\d{4})?$', '^Publisher(\s\d{4})?$', '^Project(\s\d{4})?$', '^Visio(\s\d{4})?$'
[string]$groupName2Sub      = 'Extras'
[string[]]$groupOrder2Sub   = '^Access(\s\d{4})?$', '^Publisher(\s\d{4})?$', '^Project(\s\d{4})?$', '^Visio(\s\d{4})?$'
[string]$groupName3         = 'Communications Apps'
[string[]]$groupOrder3      = '^Skype\sfor\sBusiness(\s\d{4})?$', '^Zoom$', '^(Cisco\s)?Webex$', '^Webex\sPlayer$', '^Microsoft Teams$', '^Slack$'
[string]$groupName4         = 'General Applications'
[string[]]$groupOrder4      = '^Adobe\sAcrobat\s(DC|\d{4})', '^Box\sDrive$', '^Cisco\sAnyConnect\sSecure\sMobility\sClient$'
[string[]]$taskBarItems     = 'C:\Windows\Explorer.exe', 'C:\Program Files\Internet Explorer\iexplore.exe', '^Outlook(\s\d{4})?$', '^Firefox$', '^(Google\s)?Chrome$'
$startApps   = Get-StartApps | Sort-Object -Property 'Name'
#############################################################
# FUNCTIONS
#############################################################
# DEFINE THIS FOR THE TASKBAR
Function CreateTaskBar {
    param(
        $TaskbarLinks = $taskBarItems
    )
    $TaskbarLinks.ForEach({
        Switch -regex ($_) {
            '\.exe$' {
                $targetPath = (Get-Item -Path $_).FullName
            }
            default {
                $linkObject = Get-ChildItem -Path 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs' -Recurse -ErrorAction 'Ignore' |
                    Where-Object BaseName -match $_ |
                    Select-Object FullName |
                    Select-Object -ExpandProperty 'FullName' -First 1
                $StartMenuShell = New-Object -ComObject 'WScript.Shell' -ErrorAction 'Stop'
                $targetPath     = $StartMenuShell.CreateShortcut($linkObject).TargetPath
            }
        }
        "                <taskbar:DesktopApp DesktopApplicationLinkPath=`"$targetPath`" />" | Out-File -FilePath $fileStartMenu -Append
    })
}

function CreateStartItems {
    param (
        [string]$GroupName,
        [string[]]$GroupItems,
        [string]$SubName,
        [string[]]$SubItems,
        [int]$SubRow,
        [int]$SubColumn,
        [int]$maxColumns = 5,
        [int]$maxRows = 5
    )
    # Start with a new group set at 0,0
    [int]$column          = 0
    [int]$row             = 0
    [string[]]$groupData  = "                <start:Group Name=`"$GroupName`" xmlns:start=`"http://schemas.microsoft.com/Start/2014/StartLayout`">"
    [string]$groupDataEnd = '                </start:Group>'

    # Enumerate each grouping, increasing columns and rows to a max of 6
    $GroupItems.ForEach({
        $regexApp = $_

        # regex conditioning
        if ($regexApp.Contains('#')) {
            [string]$regexAppName = $regexApp.Split('#')[0]
            [string]$regexAppID   = $regexApp.Split('#')[1]
            $idApp = $startApps.PSObject.Properties.Value.Where({$_.Name -match $regexAppName -and $_.AppID -match $regexAppID}).AppID
        }
        else {
            $idApp = $startApps.PSObject.Properties.Value.Where({$_.Name -match $regexApp}).AppID
        }

        # Enumerate programs for the group
        if ($idApp) {
            if ($column -lt $maxColumns) {
                $groupData += "                    <start:DesktopApplicationTile Size=`"2x2`" Column=`"$column`" Row=`"$row`" DesktopApplicationID=`"$idApp`" />"
                $column = $column + 2
            }
            else { #If ($column -ge $maxColumns) {
                # Start a new row
                $row = $row + 2
                $column = 0
                $groupData += "                    <start:DesktopApplicationTile Size=`"2x2`" Column=`"$column`" Row=`"$row`" DesktopApplicationID=`"$idApp`" />"
                $column = $column + 2
            }
            ###########################################################
            # SUB FOLDER QUERY
            ###########################################################
            if ($column -eq $SubColumn -and $row -eq $SubRow -and $SubName) {
                [int]$subColumn     = 0
                [int]$subRow        = 0
                [string[]]$subData  = "                    <start:Folder Name=`"$SubName`" Size=`"2x2`" Column=`"$Column`" Row=`"$Row`">"
                [string]$subDataEnd = '                    </start:Folder>'
                ForEach ($subItem in $subItems) {

                    # regex conditioning
                    if ($subItem.Contains('#')) {
                        [string]$regexSubAppName = $subItem.Split('#')[0]
                        [string]$regexSubAppID   = $subItem.Split('#')[1]
                        $idSubApp = $startApps.PSObject.Properties.Value.Where({$_.Name -match $regexSubAppName -and $_.AppID -match $regexSubAppID}).AppID
                    }
                    else {
                        $idSubApp = $startApps.PSObject.Properties.Value.Where({$_.Name -match $subItem}).AppID
                    }

                    # Enumerate programs for the group
                    if ($idSubApp) {
                        if ($subColumn -lt $maxColumns) {
                            $subData += "                        <start:DesktopApplicationTile Size=`"2x2`" Column=`"$subColumn`" Row=`"$subRow`" DesktopApplicationID=`"$idSubApp`" />"
                            $subColumn = $subColumn + 2
                        }
                        else { #If ($column -ge $maxColumns) {
                            # Start a new row
                            $subRow = $subRow + 2
                            $subColumn = 0
                            $subData += "                        <start:DesktopApplicationTile Size=`"2x2`" Column=`"$subColumn`" Row=`"$subRow`" DesktopApplicationID=`"$idSubApp`" />"
                            $subColumn = $subColumn + 2
                        }
                    }
                }

                # Close the group
                if ($subData.Count -gt 1) {
                    # Group data contains objects
                    $subData += $subDataEnd
                    $groupData += $subData
                    $column = $column + 2
                }
                else {
                    # Group data contains no objects, so return nothing
                    Write-Verbose "No data for group: $SubName"
                }
            }
            ###########################################################
        }
        else {
            Write-Verbose "Application not found: $regexApp"
        }
    })
    # Close the group
    if ($groupData.Count -gt 1) {
        # Group data contains objects
        $groupData += $groupDataEnd
        Return $groupData
    }
    else {
        # Group data contains no objects, so return nothing
        Write-Verbose "No data for group: $groupName"
    }
}
##################################################################
# Do not modify below this line
##################################################################
$sectionTop = @"
<LayoutModificationTemplate Version="1"
 xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification"
 xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout"
     xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout"
     xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout">
    <LayoutOptions StartTileGroupCellWidth="6" StartTileGroupsColumnCount="$columnsStartMenu" DeviceCategoryHint="Commercial"/>
    <DefaultLayoutOverride LayoutCustomizationRestrictionType="OnlySpecifiedGroups">
        <StartLayoutCollection>
            <defaultlayout:StartLayout GroupCellWidth="6" xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout">
"@
$sectionTaskbar = @"
            </defaultlayout:StartLayout>
        </StartLayoutCollection>
    </DefaultLayoutOverride>
    <CustomTaskbarLayoutCollection>
        <defaultlayout:TaskbarLayout>
            <taskbar:TaskbarPinList>
"@
$sectionBottom = @"
            </taskbar:TaskbarPinList>
        </defaultlayout:TaskbarLayout>
    </CustomTaskbarLayoutCollection>
</LayoutModificationTemplate>
"@
##################################################################
$sectionTop | Out-File -FilePath $fileStartMenu -Force
CreateStartItems -GroupName $groupName1 -GroupItems $groupOrder1 | Out-File -FilePath $fileStartMenu -Append
CreateStartItems -GroupName $groupName2 -GroupItems $groupOrder2 -SubName $groupName2Sub -SubItems $groupOrder2Sub -SubRow 2 -SubColumn 4 | Out-File -FilePath $fileStartMenu -Append
#CreateStartItems -GroupName $groupName2 -GroupItems $groupOrder2NoSub | Out-File -FilePath $fileStartMenu -Append
CreateStartItems -GroupName $groupName3 -GroupItems $groupOrder3 | Out-File -FilePath $fileStartMenu -Append
CreateStartItems -GroupName $groupName4 -GroupItems $groupOrder4 | Out-File -FilePath $fileStartMenu -Append
$sectionTaskbar | Out-File -FilePath $fileStartMenu -Append
CreateTaskBar -GroupName $taskBarItems
$sectionBottom | Out-File -FilePath $fileStartMenu -Append

# Refresh the Start Menu layout
Get-Process -Name 'StartMenuExperienceHost' | Stop-Process -Force
