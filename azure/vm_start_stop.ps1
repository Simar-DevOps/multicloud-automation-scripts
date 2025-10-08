param(
    [Parameter(Mandatory=$true)][ValidateSet("Start","Stop")] [string]$Action,
    [Parameter(Mandatory=$true)][string]$TagName,
    [Parameter(Mandatory=$true)][string]$TagValue,
    [string]$ResourceGroup,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$ScriptDir  = Split-Path -Parent $PSCommandPath
$HelperPath = Join-Path (Join-Path $ScriptDir '..') 'common\helpers.ps1'
. $HelperPath

Require-Tool az
Load-DotEnv

Write-Log INFO "Finding Azure VMs with tag ${TagName}=${TagValue} $(if($ResourceGroup){"in RG ${ResourceGroup}"})"

$rgArg = ($ResourceGroup) ? "--resource-group ${ResourceGroup}" : ""
$listCmd = "az vm list ${rgArg} --show-details --query ""[?tags.${TagName}=='${TagValue}'].{id:id,power:powerState,name:name}"" -o json"
$json = Invoke-CLI -Command $listCmd -DryRun:$DryRun

$vms = @()
if (-not $DryRun) {
    $vms = $json | ConvertFrom-Json
}

if ($DryRun) {
    Write-Log INFO "Would query and then ${Action} matching VMs."
    exit 0
}

if (-not $vms -or $vms.Count -eq 0) {
    Write-Log WARN "No VMs matched."
    exit 0
}

$targets = @()
foreach ($vm in $vms) {
    if ($Action -eq "Start" -and $vm.power -match "stopped") { $targets += $vm.id }
    if ($Action -eq "Stop"  -and $vm.power -match "running") { $targets += $vm.id }
}

if ($targets.Count -eq 0) {
    Write-Log WARN "Nothing to ${Action} (VMs already in desired state)."
    exit 0
}

$ids = $targets -join ' '
Write-Log INFO "${Action} -> $ids"

$cmd = if ($Action -eq "Start") {
    "az vm start --ids $ids"
} else {
    "az vm deallocate --ids $ids"
}
Invoke-CLI -Command $cmd -DryRun:$DryRun | Out-Null

Write-Log INFO "Done."
