Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$SetupArgs
)

$BootstrapUrl = "https://raw.githubusercontent.com/aspain/git-sweaty/main/scripts/bootstrap.sh"

function Write-Info {
    param([string]$Message)
    Write-Host $Message
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Read-YesNo {
    param(
        [string]$Prompt,
        [string]$Default = "Y"
    )

    $suffix = if ($Default -eq "Y") { "[Y/n]" } else { "[y/N]" }
    while ($true) {
        $answer = Read-Host "$Prompt $suffix"
        if ([string]::IsNullOrWhiteSpace($answer)) {
            return $Default -eq "Y"
        }

        switch ($answer.Trim().ToLowerInvariant()) {
            "y" { return $true }
            "yes" { return $true }
            "n" { return $false }
            "no" { return $false }
            default { Write-Host "Please enter y or n." }
        }
    }
}

function Join-BashArgs {
    param([string[]]$Items)

    $quoted = @()
    foreach ($item in $Items) {
        if ($null -eq $item) {
            continue
        }
        if ($item -eq "") {
            $quoted += "''"
            continue
        }
        $quoted += "'" + ($item -replace "'", "'""'""'") + "'"
    }
    return ($quoted -join " ")
}

function Invoke-WslInstall {
    Write-Info "Running: wsl --install -d Ubuntu"
    & wsl.exe --install -d Ubuntu
    if ($LASTEXITCODE -ne 0) {
        throw "WSL installation did not complete successfully."
    }
    Write-Info ""
    Write-Info "WSL installation was started successfully."
    Write-Info "Windows may ask you to restart and complete Ubuntu first-run setup."
    Write-Info "After that, run this same setup command again."
    exit 0
}

function Ensure-WslReady {
    $wslCommand = Get-Command wsl.exe -ErrorAction SilentlyContinue
    if ($null -eq $wslCommand) {
        Write-Info "Windows setup requires WSL and a Linux distro (Ubuntu recommended)."
        if (Test-Administrator) {
            if (Read-YesNo "WSL is not installed. Try to install WSL with Ubuntu now?" "Y") {
                Invoke-WslInstall
            }
        } else {
            Write-Info "Run PowerShell as Administrator once and execute: wsl --install -d Ubuntu"
        }
        throw "WSL is required before continuing."
    }

    $distros = @(& wsl.exe -l -q 2>$null)
    $trimmedDistros = @($distros | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($LASTEXITCODE -ne 0 -or $trimmedDistros.Count -eq 0) {
        Write-Info "WSL is installed, but no Linux distro is ready yet."
        if (Test-Administrator) {
            if (Read-YesNo "Try to install Ubuntu now?" "Y") {
                Invoke-WslInstall
            }
        } else {
            Write-Info "Run PowerShell as Administrator once and execute: wsl --install -d Ubuntu"
        }
        throw "A WSL distro is required before continuing."
    }
}

Ensure-WslReady

$bootstrapCommand = "bash <(curl -fsSL $BootstrapUrl)"
if ($SetupArgs.Count -gt 0) {
    $bootstrapCommand = "$bootstrapCommand $(Join-BashArgs $SetupArgs)"
}

Write-Info "Launching setup inside WSL..."
& wsl.exe bash -lc $bootstrapCommand
exit $LASTEXITCODE
