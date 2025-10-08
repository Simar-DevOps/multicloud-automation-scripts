@'

\# multicloud-automation-scripts



PowerShell automation for \*\*AWS\*\* and \*\*Azure\*\*:

\- Start/stop compute by \*\*tag\*\*

\- (Planned) Storage sync (S3/Blob) and more

\- Safe `-DryRun` everywhere, shared helpers, CI linting



!\[CI](https://img.shields.io/github/actions/workflow/status/simar-devops/multicloud-automation-scripts/ci.yml?branch=main)

!\[License](https://img.shields.io/badge/License-MIT-green.svg)



---



\## 🚀 Quick Start



```pwsh

\# AWS example (no changes made)

pwsh ./aws/ec2\_start\_stop.ps1 -Action Start -TagKey Role -TagValue Web -Region us-east-1 -DryRun



\# Azure example (no changes made)

pwsh ./azure/vm\_start\_stop.ps1 -Action Stop -TagName Role -TagValue Web -ResourceGroup rg-sandbox -DryRun
Remove -DryRun to actually execute.



multicloud-automation-scripts/

├─ aws/

│  └─ ec2\_start\_stop.ps1        # Start/Stop EC2 by tag (safe, idempotent)

├─ azure/

│  └─ vm\_start\_stop.ps1         # Start/Stop VMs by tag (safe, idempotent)

├─ common/

│  └─ helpers.ps1               # Logging, tool checks, dotenv, safe CLI

├─ docs/

│  └─ usage\_matrix.md           # One-page reference

├─ .github/workflows/

│  └─ ci.yml                    # Lint + dry-run smoke tests

├─ .gitignore

├─ LICENSE

└─ README.md

✅ Prerequisites



Windows 10/11 with PowerShell 7+ (pwsh)



AWS CLI v2 configured (e.g., profile with perms to describe/start/stop EC2)



Azure CLI (az) logged in and subscription selected



(Optional) Git + GitHub CLI for contributing



Verify:
aws --version

az version

pwsh -v

git --version

🔧 Setup
# Clone (if opening fresh) or just run scripts inside your existing folder

git clone https://github.com/simar-devops/multicloud-automation-scripts.git

Set-Location multicloud-automation-scripts


Environment variables (.env optional):

Create a .env file (excluded by .gitignore) for convenience:
AWS\_PROFILE=default

AZ\_SUBSCRIPTION\_ID=<your-sub-guid>

The helper auto-loads .env if present (keys become process env vars).


🧪 Usage

AWS — EC2 start/stop by tag
# Dry run

pwsh ./aws/ec2\_start\_stop.ps1 -Action Start -TagKey Role -TagValue Web -Region us-east-1 -DryRun



\# Real run (uses default AWS profile/region unless overridden)

pwsh ./aws/ec2\_start\_stop.ps1 -Action Stop -TagKey Role -TagValue Web -Region us-east-1


What it does



Finds instances with tag:Role=Web



Starts only those currently stopped (or stops only those running)



Prints exactly what it will change; exits gracefully if nothing to do



Key params



-Action Start|Stop (required)



-TagKey, -TagValue (required)



-Region us-east-1 (default shown)



-Profile <aws-profile-name> (optional)



-DryRun (safe preview)

Azure — VM start/stop by tag
# Dry run

pwsh ./azure/vm\_start\_stop.ps1 -Action Stop -TagName Role -TagValue Web -ResourceGroup rg-sandbox -DryRun



\# Real run

pwsh ./azure/vm\_start\_stop.ps1 -Action Start -TagName Role -TagValue Web -ResourceGroup rg-sandbox


What it does



Lists VMs with tag Role=Web (optionally within rg-sandbox)



Starts only stopped VMs, stops only running VMs



Uses az vm start / az vm deallocate with proper safeguards



Key params



-Action Start|Stop (required)



-TagName, -TagValue (required)



-ResourceGroup <name> (recommended for smaller scope)



-DryRun (safe preview)

🧰 Common Helpers



./common/helpers.ps1 provides:



Write-Log — timestamped INFO/WARN/ERROR messages



Require-Tool — ensures required CLIs exist



Load-DotEnv — loads .env into process environment



Invoke-CLI — runs external commands with error capture and -DryRun support



All scripts dot-source this helper for consistent behavior.

🛡️ Safety \& Idempotence



Dry Run First: Every script supports -DryRun to print actions without making changes.



State-aware: Scripts only operate on resources in the appropriate current state.



Scoped by Tag: Use tight tag selectors to avoid broad changes.

🧱 CI/CD



GitHub Actions runs on push and pull\_request:



PowerShell linting via PSScriptAnalyzer



Dry-run execution of sample commands to catch argument regressions



Badge at top shows status for main.

🐛 Troubleshooting



az: command not found

Install Azure CLI (Winget: winget install Microsoft.AzureCLI), open new PowerShell.



AWS auth/region issues

Set profile/region explicitly: -Profile myprofile -Region us-east-1, or run aws configure.



Nothing happens

Likely no resources matched your tag or they’re already in the desired state. Use -DryRun to verify selection.



Permissions

Ensure your identities have Describe/Start/Stop on EC2 (AWS) or Microsoft.Compute/\*/read,start,deallocate on VM (Azure).

🗺️ Roadmap



S3 ↔ folder sync + Azure Blob ↔ folder sync (with azcopy)



Pester tests for helper functions



Parameterized config profiles



Release pipeline with signed artifacts

🤝 Contributing



PRs welcome! Please:



Run Invoke-ScriptAnalyzer locally.



Keep scripts idempotent and include -DryRun.



Update docs/usage\_matrix.md when adding new scripts.

