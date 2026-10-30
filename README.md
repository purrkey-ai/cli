# Purrkey CLI

Official Purrkey CLI releases and installation scripts. This repository distributes
the `purrkey` executable for macOS, Linux and Windows; application source lives separately.

## Install on macOS or Linux

```bash
installer="$(mktemp)"
curl -fsSL https://github.com/purrkey-ai/cli/releases/latest/download/install.sh -o "$installer"
bash "$installer"
rm -f "$installer"
export PATH="$HOME/.local/bin:$PATH"
purrkey version
```

The installer checks the archive's SHA256 and executable version before replacing
`purrkey` in `~/.local/bin`. Set `ATX_INSTALL_DIR` to choose another directory.

## Install on Windows x64

Run in PowerShell:

```powershell
$installer = Join-Path $env:TEMP 'purrkey-install.ps1'
Invoke-WebRequest https://github.com/purrkey-ai/cli/releases/latest/download/install.ps1 -OutFile $installer
& $installer
Remove-Item $installer
purrkey version
```

The installer uses `%LOCALAPPDATA%\Purrkey\bin`, verifies SHA256 and adds the directory
to the current PowerShell session's PATH. Add it to your user PATH for future terminals.
If your system's execution policy blocks scripts, download and verify the archive
manually rather than weakening the policy.

## Configure

Create an API Key on [the website](https://ai.pkmon.app/keys) and configure
it locally:

```sh
purrkey config
```

Paste the key into the hidden prompt and press Enter. The CLI connects to Purrkey.ai,
verifies access and saves your key automatically. Keep the key out of chat and command arguments.
For scripted secret stores, use `purrkey config --key-stdin`.
Agent instructions: [SKILL.md](https://ai.pkmon.app/SKILL.md).

Re-run the installer to update. Published release assets are immutable; each release
contains platform archives, both installers, the Skill, `VERSION` and `SHA256SUMS`.
