#requires -Modules Microsoft.Graph
param()

Connect-MgGraph -Scopes "PrivilegedAccess.ReadWrite.AzureADGroup" -NoWelcome
$user = Get-MgUser -UserId (Get-MgContext).Account
$eligibleGroups = Get-MgIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance -Filter "principalId eq '$($user.Id)'"
$activeGroupIds = (Get-MgIdentityGovernancePrivilegedAccessGroupAssignmentScheduleInstance -Filter "principalId eq '$($user.Id)'") | ForEach-Object { $_.GroupId }

if (-not $eligibleGroups) { Write-Host "Inga grupper tillgängliga för aktivering via PIM."; exit }

$groupList = foreach ($g in $eligibleGroups) {
    try { $group = Get-MgGroup -GroupId $g.GroupId } catch { $group = $null }
    [PSCustomObject]@{ Name = $group.DisplayName; Id = $g.GroupId; IsActive = $activeGroupIds -contains $g.GroupId }
}

Write-Host " -- PIM GROUPS -- `n------------------------------"
for ($i = 0; $i -lt $groupList.Count; $i++) {
    $s = if ($groupList[$i].IsActive) { "$( [char]0x2714 ) AKTIV" } else { "$( [char]0x2718 ) INAKTIV" }
    $c = if ($groupList[$i].IsActive) { 'Green' } else { 'Red' }
    Write-Host ("$($i+1). [$s] - $($groupList[$i].Name) [$($groupList[$i].Id)]") -ForegroundColor $c
}
Write-Host "------------------------------"
$choice = Read-Host "Ange numret på gruppen du vill aktivera (eller 'A' för alla)"

if ($choice -eq 'A' -or $choice -eq 'a') {
    foreach ($g in $groupList) {
        if (-not $g.IsActive) {
            $body = @{ action = "selfActivate"; accessId = "member"; groupId = $g.Id; principalId = $user.Id; scheduleInfo = @{ startDateTime = (Get-Date).ToString("o"); expiration = @{ type = "afterDuration"; duration = "PT8H" } }; justification = "access till pim group $($g.Name) för att utföra nödvändiga uppgifter" } | ConvertTo-Json -Depth 10
            try {
                Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests" -Body $body -ContentType "application/json" | Out-Null
                $justification = ($body | ConvertFrom-Json).justification
                Write-Host ("Aktivering av $($g.Name) har skickats med följande motivering: $justification")
                Write-Host ("Aktiveringen gäller till: $((Get-Date).AddHours(8).ToString('yyyy-MM-dd HH:mm'))")
            } catch { Write-Host "Fel vid aktivering av $($g.Name): $_" }
        } else { Write-Host ("Hoppar över $($g.Name) (redan aktiv)") }
    }
    exit
}

if ($choice -notmatch '^[0-9]+$' -or [int]$choice -lt 1 -or [int]$choice -gt $groupList.Count) { Write-Host "Ogiltigt val."; exit }
$g = $groupList[[int]$choice - 1]
$body = @{ action = "selfActivate"; accessId = "member"; groupId = $g.Id; principalId = $user.Id; scheduleInfo = @{ startDateTime = (Get-Date).ToString("o"); expiration = @{ type = "afterDuration"; duration = "PT8H" } }; justification = "access till pim group $($g.Name) för att utföra nödvändiga uppgifter" } | ConvertTo-Json -Depth 10
try {
    Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests" -Body $body -ContentType "application/json" | Out-Null
    $justification = ($body | ConvertFrom-Json).justification
    Write-Host ("Aktivering av $($g.Name) har skickats med följande motivering: $justification")
    Write-Host ("Aktiveringen gäller till: $((Get-Date).AddHours(8).ToString('yyyy-MM-dd HH:mm'))")
} catch { Write-Host "Fel vid aktivering: $_" }
