param(
  [Parameter(Mandatory=$true)][ValidateSet("Start","Stop")] [string]$Action,
  [Parameter(Mandatory=$true)][string]$TagKey,
  [Parameter(Mandatory=$true)][string]$TagValue,
  [string]$Region = "us-east-1",
  [string]$Profile,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# NO helper imports, NO expandable strings, NO colon-adjacent variables.
if ($DryRun) {
  Write-Host ("DRY-RUN OK :: Action={0} TagKey={1} TagValue={2} Region={3}" -f $Action,$TagKey,$TagValue,$Region)
  exit 0
}

Write-Host ("REAL RUN PATH :: Action={0} TagKey={1} TagValue={2} Region={3}" -f $Action,$TagKey,$TagValue,$Region)
exit 0
