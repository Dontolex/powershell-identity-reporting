#requires -Version 7.0
<#
.SYNOPSIS
Reads the lab employee profile and direct groups, and saves a dated text report.
.DESCRIPTION
Run from an existing authenticated PowerShell 7 session. No tenant data is changed.
#>
[CmdletBinding()]
param(
    [string]$UserId = '509c8d28-6157-44c4-bf95-588348981d3a',
    [string]$OutputDirectory = (Join-Path $PSScriptRoot 'reports')
)

$ErrorActionPreference = 'Stop'
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.Users -ErrorAction Stop

# Use the connection already established in this PowerShell window.
$context = Get-MgContext
if (-not $context) {
    throw 'No Graph connection. Connect to your lab in this PowerShell 7 window, then run the script again.'
}
if ($context.TenantId -ne 'fa8614ce-2e10-441b-b3a4-619052db0946') {
    throw 'The current connection is not for the expected lab tenant. Connect to the lab before continuing.'
}

# Read fresh data on every run. A failed query stops report creation.
$user = Get-MgUser -UserId $UserId -Property DisplayName,Department,JobTitle -ErrorAction Stop
$groups = @(Get-MgUserMemberOfAsGroup -UserId $UserId -All -Property DisplayName,Id -ErrorAction Stop)
$collectedAt = [DateTimeOffset]::UtcNow
$report = [pscustomobject]@{
    DisplayName = $user.DisplayName
    Department = $user.Department
    JobTitle = $user.JobTitle
    DirectGroupCount = $groups.Count
}

$lines = @(
    'Lab employee identity report'
    "Collected at (UTC): $($collectedAt.ToString('o'))"
    "Tenant ID: $($context.TenantId)"
    "User ID: $UserId"
    ''
    ($report | Format-List | Out-String -Width 200).Trim()
    ''
    'Direct group memberships:'
)
if ($groups.Count -eq 0) {
    $lines += 'No direct group memberships returned.'
} else {
    $lines += ($groups | Sort-Object DisplayName | Select-Object DisplayName,Id | Format-Table -AutoSize | Out-String -Width 200).Trim()
}
$lines += @('', 'Scope: profile and direct group memberships only. This is not a complete effective-access review.', 'Profile and memberships were read sequentially; they are not an atomic snapshot.')

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$filename = 'lab-employee-{0}-{1}.txt' -f $collectedAt.ToString('yyyyMMdd-HHmmssfff'),([guid]::NewGuid().ToString('N').Substring(0,8))
$reportPath = Join-Path $OutputDirectory $filename
$lines | Out-File -LiteralPath $reportPath -Encoding utf8 -NoClobber
$report | Format-Table -AutoSize
Write-Host "Report saved: $reportPath"
