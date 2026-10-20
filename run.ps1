# Run QueryAI on Windows.
#
#   .\run.ps1                          # interactive TUI in the current directory
#   .\run.ps1 "explain this repo"      # one-off prompt
#   .\run.ps1 -Model groq/llama-3.3-70b-versatile "..."
#   .\run.ps1 -Dir C:\path\to\project  # open a different project
#
# If you get "running scripts is disabled", run once:
#   powershell -ExecutionPolicy Bypass -File .\run.ps1

[CmdletBinding(PositionalBinding = $false)]
param(
  [string]$Model = "google/gemini-3.7-flash",
  [string]$Dir = (Get-Location).Path,
  [Parameter(ValueFromRemainingArguments = $true)][string[]]$Prompt
)

$ErrorActionPreference = "Stop"

# 1. Install if missing
if (-not (Get-Command queryai -ErrorAction SilentlyContinue)) {
  if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Error "QueryAI needs Node.js 18+ to install. Get it from https://nodejs.org and re-run."
  }
  Write-Host "Installing QueryAI..." -ForegroundColor Cyan
  npm install -g queryai
  $env:Path = "$(npm prefix -g);$env:Path"
}
Write-Host "QueryAI $(queryai --version)" -ForegroundColor Green

# 2. Make sure at least one provider key is configured
$models = queryai models 2>$null
if (-not $models) {
  Write-Host "No provider keys yet. Pick one (Google, Groq and OpenRouter have free tiers)." -ForegroundColor Yellow
  queryai providers login
  $models = queryai models 2>$null
  if (-not $models) { Write-Error "Still no models available. Check your key with: queryai providers list" }
}

# 3. Fall back to the first available model if the default is not unlocked
if ($models -notcontains $Model) {
  $Model = ($models | Select-Object -First 1)
  Write-Host "Default model not available, using $Model" -ForegroundColor Yellow
}

# 4. Launch
Set-Location $Dir
if ($Prompt) {
  queryai run -m $Model ($Prompt -join " ")
} else {
  queryai -m $Model
}
