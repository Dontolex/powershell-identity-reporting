# Batch reporting and continuing after a failed lookup

## Objective

Run the existing identity-reporting script for several lab users, capture an individual lookup failure and continue to the next user. This extends the single-user reporting exercise without changing the original script.

## Verified results

On 25 September 2026, the input list contained Lab Employee, a nonexistent ID and Review HR, in that order.

| Order | Input | Observed outcome | Evidence |
| --- | --- | --- | --- |
| 1 | Lab Employee | Report saved at 13:06:16 UTC; 0 direct groups returned | [Report](evidence/batch-lab-employee-report.txt) |
| 2 | Nonexistent user ID | Request_ResourceNotFound recorded in the failure collection | [Saved failure log](evidence/batch-failures-20260925.txt) |
| 3 | Review HR | Report saved at 13:06:19 UTC; 1 direct group, LAB-HR-Review | [Report](evidence/batch-review-hr-report.txt) |

Both successful reports and the subsequently saved failure log were inspected locally. The results demonstrate continuation after the intermediate lookup failure. The existing screenshot documents the earlier single-user exercise, not this batch test.

## The tested loop

Run in an authenticated PowerShell 7 session from the project folder. The loop below reproduces the tested interactive logic; only the script location has been changed from the original machine-specific absolute path to a relative path.

```powershell
$testUsers = @(
    "509c8d28-6157-44c4-bf95-588348981d3a"
    "00000000-0000-0000-0000-000000000000"
    "252af843-34f0-4b48-bffa-7bd64e458d28"
)

$failedUsers = @()

foreach ($labUserId in $testUsers) {
    try {
        & ".\Get-LabEmployeeReport.ps1" -UserId $labUserId
    }
    catch {
        $failedUsers += [pscustomobject]@{
            UserId = $labUserId
            Error  = $_.Exception.Message
        }
        Write-Warning "Could not report on $labUserId. Continuing."
    }
}

$failedUsers | Format-List
```

The successful script calls create the reports directory. In the tested run, the failure collection was then saved with the following command, originally using an absolute path to the same destination:

```powershell
$failedUsers | Format-List | Out-File -FilePath ".\reports\batch-failures-20260925.txt" -Encoding utf8
```

This fixed failure-log filename records the lab date and is overwritten if that export command is repeated. Use a new filename to retain a separate log for another run. If no successful report has created the reports directory, create it before exporting the failure collection.

## What I learned

- `foreach` runs the same action for each ID in the list.
- `try` attempts the individual report.
- `catch` captures a terminating error and records the user ID and error message.
- After the catch block, the loop advances to the next ID.
- The failure collection remains in session memory until explicitly saved.

The individual report stopped for the invalid user, while the batch continued. This prevents one missing user from blocking reports for the remaining users.

## Limitations

This is a sequential, interactive batch exercise producing separate user reports, not a combined report or scheduled service. The demonstrated failure is a nonexistent user; authentication failures, throttling, network outages and file-write failures were not tested. The catch block records any terminating error, so an error must be inspected before concluding that a user does not exist. No accounts or memberships were changed.
