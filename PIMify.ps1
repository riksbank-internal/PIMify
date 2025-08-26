#requires -Modules Microsoft.Graph
param()

Connect-MgGraph -Scopes "PrivilegedAccess.ReadWrite.AzureADGroup" -NoWelcome
$user = Get-MgUser -UserId (Get-MgContext).Account
$eligibleGroups = Get-MgIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance -Filter "principalId eq '$($user.Id)'"
$activeGroupIds = (Get-MgIdentityGovernancePrivilegedAccessGroupAssignmentScheduleInstance -Filter "principalId eq '$($user.Id)'") | ForEach-Object { $_.GroupId }

if (-not $eligibleGroups) { Write-Host "No groups available for activation via PIM."; exit }

$groupList = foreach ($g in $eligibleGroups) {
    try { $group = Get-MgGroup -GroupId $g.GroupId } catch { $group = $null }
    [PSCustomObject]@{ Name = $group.DisplayName; Id = $g.GroupId; IsActive = $activeGroupIds -contains $g.GroupId }
}

Write-Host " -- PIM GROUPS -- `n------------------------------"
for ($i = 0; $i -lt $groupList.Count; $i++) {
    $s = if ($groupList[$i].IsActive) { "$( [char]0x2714 ) ACTIVE" } else { "$( [char]0x2718 ) INACTIVE" }
    $c = if ($groupList[$i].IsActive) { 'Green' } else { 'Red' }
    Write-Host ("$($i+1). [$s] - $($groupList[$i].Name) [$($groupList[$i].Id)]") -ForegroundColor $c
}
Write-Host "------------------------------"
$choice = Read-Host "Enter the number of the group you want to activate (or 'A' for all)"

if ($choice -eq 'A' -or $choice -eq 'a') {
    foreach ($g in $groupList) {
        if (-not $g.IsActive) {
            $body = @{ action = "selfActivate"; accessId = "member"; groupId = $g.Id; principalId = $user.Id; scheduleInfo = @{ startDateTime = (Get-Date).ToString("o"); expiration = @{ type = "afterDuration"; duration = "PT8H" } }; justification = "access to pim group $($g.Name) to perform necessary tasks" } | ConvertTo-Json -Depth 10
            try {
                Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests" -Body $body -ContentType "application/json" | Out-Null
                $justification = ($body | ConvertFrom-Json).justification
                Write-Host ("Activation of $($g.Name) has been sent with the following justification: $justification")
                Write-Host ("The activation is valid until: $((Get-Date).AddHours(8).ToString('yyyy-MM-dd HH:mm'))")
            } catch { Write-Host "Error during activation of $($g.Name): $_" }
        } else { Write-Host ("Skipping $($g.Name) (already active)") }
    }
    exit
}

if ($choice -notmatch '^[0-9]+$' -or [int]$choice -lt 1 -or [int]$choice -gt $groupList.Count) { Write-Host "Invalid choice."; exit }
$g = $groupList[[int]$choice - 1]
$body = @{ action = "selfActivate"; accessId = "member"; groupId = $g.Id; principalId = $user.Id; scheduleInfo = @{ startDateTime = (Get-Date).ToString("o"); expiration = @{ type = "afterDuration"; duration = "PT8H" } }; justification = "access to pim group $($g.Name) to perform necessary tasks" } | ConvertTo-Json -Depth 10
try {
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests" -Body $body -ContentType "application/json" | Out-Null
    $justification = ($body | ConvertFrom-Json).justification
    Write-Host ("Activation of $($g.Name) has been sent with the following justification: $justification")
    Write-Host ("The activation is valid until: $((Get-Date).AddHours(8).ToString('yyyy-MM-dd HH:mm'))")
} catch { Write-Host "Error during activation: $_" }
