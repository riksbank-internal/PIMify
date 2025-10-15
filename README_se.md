# PIMify

Ett litet PowerShell‑skript som självaktiverar dina berättigade Microsoft Entra ID (Azure AD) gruppmedlemskap via Privileged Identity Management (PIM) med hjälp av Microsoft Graph PowerShell SDK.

<img width="1252" height="236" alt="image" src="https://github.com/user-attachments/assets/ef7f1e23-e650-403d-9790-2116f430d958" />

## Vad skriptet gör

- Ansluter till Microsoft Graph med omfånget `PrivilegedAccess.ReadWrite.AzureADGroup`.
- Identifierar den inloggade användaren och listar alla Azure AD‑grupper där användaren är berättigad för PIM‑aktivering.
- Visar om varje grupp redan är aktiv för användaren.
- Låter dig välja en enskild grupp via ett nummer eller aktivera alla inaktiva berättigade grupper på en gång.
- Skickar en aktiveringsbegäran som startar direkt och varar i 8 timmar, med en svensk standardmotivering.

Observera
- Skriptets UI/meddelanden är på svenska.
- Aktiveringar begärs med `accessId` `member` (inte `owner`).
- Standardvaraktighet är 8 timmar (`PT8H`). Detta kan ändras i skriptet.

## Förutsättningar

- PowerShell
  - Rekommenderat: PowerShell 7+ (Windows/macOS/Linux), eller Windows PowerShell 5.1.
- Microsoft Graph PowerShell SDK
  - Installera vid behov: `Install-Module Microsoft.Graph -Scope CurrentUser`
- Behörigheter
  - Ditt konto måste ha rätt att självaktivera gruppmedlemskap via PIM.
  - Appen begär Graph‑omfånget `PrivilegedAccess.ReadWrite.AzureADGroup` vid inloggning (administratörsgodkännande kan krävas i din klient).

## Användning

Skriptfilen heter `# PIMify.ps1`. Eftersom filnamnet innehåller `#` och ett blanksteg måste du citera sökvägen när du kör den.

Windows (PowerShell)

```powershell
# Från repo‑roten
& ".\# PIMify.ps1"
```

PowerShell 7 på macOS/Linux/Windows

```powershell
& "./# PIMify.ps1"
```

Från Bash/zsh (anropar PowerShell 7)

```bash
pwsh -File "./# PIMify.ps1"
```

Vad du kan förvänta dig
1) Du uppmanas att logga in mot Microsoft Graph.
2) En lista över PIM‑berättigade grupper visas med status:
   - ✔ AKTIV = aktiv
   - ✘ INAKTIV = inaktiv
3) Ange numret på en grupp för att aktivera den, eller `A` för att aktivera alla inaktiva grupper.

## Beteendedetaljer

- Listar berättigande via:
  - `Get-MgIdentityGovernancePrivilegedAccessGroupEligibilityScheduleInstance`
  - Aktiva tilldelningar via `Get-MgIdentityGovernancePrivilegedAccessGroupAssignmentScheduleInstance`
- Aktiveringsbegäran skickas till:
  - `POST /v1.0/identityGovernance/privilegedAccess/group/assignmentScheduleRequests`
- Nyckelfält i begäran:
  - `action`: `selfActivate`
  - `accessId`: `member`
  - `scheduleInfo.startDateTime`: nu
  - `scheduleInfo.expiration`: `afterDuration` med `PT8H`
  - `justification`: svensk motivering som finns i skriptet

## Anpassa

- Varaktighet: ändra `"duration": "PT8H"` till exempelvis `"PT4H"` eller `"PT2H"`.
- Motivering: uppdatera den svenska motiveringen till er standardtext.
- Åtkomstnivå: om lämpligt kan `accessId` ändras från `member` till `owner` för ägarnivå‑aktivering.

## Felsökning

- “Inga grupper tillgängliga”: du har inga PIM‑berättigade grupper eller saknar behörigheter.
- “Ogiltigt val.”: inmatningen var inte ett giltigt nummer inom intervallet eller `A`.
- Autentisering/samtycke‑fel i Graph: säkerställ att `Microsoft.Graph` är installerad och att ditt konto/klient tillåter efterfrågade omfång; administratörssamtycke kan krävas.
- Modul saknas: kör `Install-Module Microsoft.Graph -Scope CurrentUser` och starta om PowerShell.

## Säkerhet

- Inloggning sker interaktivt med ditt Entra ID‑konto. Kontrollera att du loggar in mot rätt klient/kontekst.
