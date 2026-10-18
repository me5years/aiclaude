param([string]$Site = 'https://netlify-token-app.netlify.app')
$ErrorActionPreference = 'Stop'
try {
  $siteUri = [Uri]$Site
  if ($siteUri.Scheme -ne 'https' -or $siteUri.Host -notmatch '^[a-zA-Z0-9.-]+$' -or $siteUri.UserInfo -or $siteUri.AbsolutePath -ne '/' -or $siteUri.Query -or $siteUri.Fragment) { throw 'Use the HTTPS origin of your published Relay site.' }
  $Site = $siteUri.GetLeftPart([UriPartial]::Authority)
  $nodeCommand = Get-Command node -ErrorAction SilentlyContinue
  if (-not $nodeCommand) { throw 'Install Node.js 22 LTS or newer from https://nodejs.org, then run this installer again.' }
  $nodeVersion = & node --version
  $nodeMajor = [int]($nodeVersion.TrimStart('v').Split('.')[0])
  if ($nodeMajor -lt 22) { throw 'Relay requires Node.js 22 or newer.' }
  $installDirectory = Join-Path $env:LOCALAPPDATA 'RelayBridge'
  New-Item -ItemType Directory -Path $installDirectory -Force | Out-Null
  $bridgePath = Join-Path $installDirectory 'bridge.mjs'
  Invoke-WebRequest -Uri "$Site/bridge.mjs" -OutFile "$bridgePath.download" -UseBasicParsing
  Move-Item -Path "$bridgePath.download" -Destination $bridgePath -Force
  $launcherPath = Join-Path $installDirectory 'Start Relay.cmd'
  $launcher = "@echo off`r`ntitle Relay - Local Claude Code Bridge`r`nnode `"%~dp0bridge.mjs`" --site `"$Site`"`r`nif errorlevel 1 pause`r`n"
  [IO.File]::WriteAllText($launcherPath, $launcher, [Text.Encoding]::ASCII)
  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'Relay.lnk'))
  $shortcut.TargetPath = $launcherPath
  $shortcut.WorkingDirectory = $installDirectory
  $shortcut.Description = 'Relay - local Netlify connection for Claude Code'
  $shortcut.Save()
  Write-Host 'Relay installed. Open the Relay desktop shortcut whenever you need the bridge.' -ForegroundColor Green
  Write-Host 'Keep the bridge window open while using Claude Code.'
  Start-Process -FilePath $launcherPath
} catch {
  Write-Host 'Installation could not complete. Check Node.js 22+, internet access, and the published site address.' -ForegroundColor Red
  Write-Host 'No Netlify tokens are needed in this installer.'
  exit 1
}
