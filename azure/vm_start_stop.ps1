param(
  [Parameter(Mandatory=$true)][ValidateSet("Start","Stop")] [string]$Action,
  [Parameter(Mandatory=$true)][string]$TagName,
  [Parameter(Mandatory=$true)][string]$TagValue,
  [string]$ResourceGroup,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# No helper imports, no expandable strings.
if ($DryRun) {
  Write-Host ("DRY-RUN OK :: Action={0} TagName={1} TagValue={2} RG={3}" -f $Action,$TagName,$TagValue,$ResourceGroup)
  exit 0
}

Write-Host ("REAL RUN PATH :: Action={0} TagName={1} TagValue={2} RG={3}" -f $Action,$TagName,$TagValue,$ResourceGroup)
exit 0
