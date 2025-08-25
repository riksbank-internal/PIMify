# PIMify

A small PowerShell script to self-activate your eligible Microsoft Entra ID (Azure AD) group assignments via Privileged Identity Management (PIM) using the Microsoft Graph PowerShell SDK.

## What it does

- Connects to Microsoft Graph with the scope `PrivilegedAccess.ReadWrite.AzureADGroup`.
- Detects the signed-in user and lists all Azure AD groups where the user is eligible for PIM activation.
- Shows whether each listed group is currently active for the user.
- Lets you pick a single group by number or activate all inactive eligible groups at once.
- Submits an activation request that starts immediately and lasts 8 hours, with a default Swedish justification.

Notes
- The script UI/messages are in Swedish.
- Activations are requested with accessId `member` (not `owner`).
- Default duration is 8 hours (PT8H). You can change this in the script.

## Prerequisites

- PowerShell
	- PowerShell 7+ (Windows/macOS/Linux) recommended, or Windows PowerShell 5.1.
- Microsoft Graph PowerShell SDK
	- Install if needed: `Install-Module Microsoft.Graph -Scope CurrentUser`
- Permissions
	- Your account must have rights to self-activate group membership via PIM.
	- The app will request the Graph scope `PrivilegedAccess.ReadWrite.AzureADGroup` on sign-in (admin consent may be required in your tenant).

## Usage

The script file is named `# PIMify.ps1`. Because the filename contains a `#` and a space, you must quote it when running.

Windows (PowerShell)

```powershell
# From the repository root
& ".\# PIMify.ps1"
```

PowerShell 7 on macOS/Linux/Windows

```powershell
& "./# PIMify.ps1"
```

From Bash/zsh (calls PowerShell 7)

```bash
pwsh -File "./# PIMify.ps1"
```

What to expect
1) You’ll be prompted to sign in to Microsoft Graph.
2) A list of PIM-eligible groups is shown with status:
	 - ✔ AKTIV = active
	 - ✘ INAKTIV = inactive
3) Enter the number of a group to activate it, or `A` to activate all inactive groups.

## Behavior details

- Lists eligibility via:
	- `Get-MgIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance`
	- Active assignments via `Get-MgIdentityGovernancePrivilegedAccessGroupAssignmentScheduleInstance`
- Activation requests are sent to:
	- `POST /v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests`
- Request body key fields:
	- `action`: `selfActivate`
	- `accessId`: `member`
	- `scheduleInfo.startDateTime`: now
	- `scheduleInfo.expiration`: `afterDuration` of `PT8H`
	- `justification`: Swedish text included in the script

## Customize

- Duration: change `"duration": "PT8H"` to e.g. `"PT4H"` or `"PT2H"`.
- Justification: update the Swedish justification string to your org’s standard text.
- Access level: if appropriate in your tenant, you can switch `accessId` from `member` to `owner` for owner-level activation.

## Troubleshooting

- “Inga grupper tillgängliga”: you have no PIM-eligible groups or lack permissions.
- “Ogiltigt val.”: the input wasn’t a number in range and wasn’t `A`.
- Graph auth/consent errors: ensure `Microsoft.Graph` is installed and that your account/tenant allows the requested scope; admin consent might be required.
- Module not found: run `Install-Module Microsoft.Graph -Scope CurrentUser` and restart PowerShell.

## Security

- Sign-in is interactive using your Entra ID account. Ensure you’re signing in to the correct tenant/context.
