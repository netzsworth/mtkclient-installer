<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2024 v5.8.246
	 Created on:   	20/07/2024 10:05 SA
	 Created by:   	netzsworth
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		mtkclient installer for the unfortunate souls
#>
#Requires -RunAsAdministrator

Write-Host "---------------------------------------------------" -BackgroundColor Black -ForegroundColor Green
Write-Host "---             mtkclient-installer             ---" -BackgroundColor Black -ForegroundColor Green
Write-Host "-- mtkclient installer for the unfortunate souls --" -BackgroundColor Black -ForegroundColor Green
Write-Host "---  Made by netzsworth - netzsworth.github.io  ---" -BackgroundColor Black -ForegroundColor Green
Write-Host "---------------------------------------------------" -BackgroundColor Black -ForegroundColor Green
Write-Host "                                                   "

If (([Security.Principal.WindowsIdentity]::GetCurrent()).Owner.Value -ne "S-1-5-32-544")
{
	Write-Host "-- This script must be ran as Administrator ---" -Foregroundcolor White -BackgroundColor DarkRed
	break
}

function install-winget
{
	# Get the download URL of the latest winget installer from GitHub:
	$API_URL = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
	$DOWNLOAD_URL = $(Invoke-RestMethod $API_URL).assets.browser_download_url |
	Where-Object { $_.EndsWith(".msixbundle") }
	
	# Download the installer:
	Invoke-WebRequest -URI $DOWNLOAD_URL -OutFile winget.msixbundle -UseBasicParsing
	
	# Install winget:
	Add-AppxPackage winget.msixbundle
	
	# Remove the installer:
	Remove-Item winget.msixbundle
	$winget = $True
}
function install-choco
{
	Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
	$choco = $True
}
Write-Host "Checking if Chocolatey is installed..."
if ((Get-Command -Name choco -ErrorAction Ignore) -and ($chocoVersion = (Get-Item "$env:ChocolateyInstall\choco.exe" -ErrorAction Ignore).VersionInfo.ProductVersion))
{
	Write-Host "--- Chocolatey is installed ---" -ForegroundColor White -BackgroundColor DarkGreen
	Write-Host "Version: v$chocoVersion" -ForegroundColor White
	$choco = $True
}
else
{
	Write-Host "--- Chocolatey is not installed ---"
	$choco = $false
}

# Check if Winget is installed, then proceed
$winget = $True
Write-Host "Checking if WinGet is installed..."
try
{
	$winget = winget --version
}
catch [System.Management.Automation.CommandNotFoundException], [System.Management.Automation.ApplicationFailedException] {
	$winget = $False
	if ($choco -eq $false)
	{
		Write-Host "Looks like neither Chocolatey or WinGet are installed, make a selection:" -BackgroundColor DarkRed -ForegroundColor White
		Write-Host "G: Install WinGet"
		Write-Host "C: Install Chocolatey"
		Write-Host "Any other key: Skip python and git installation (only if you already have it installed)"
		$selection = Read-Host "Make a selection"
	}
}

catch
{
	$winget = $False
	if ($choco -eq $false)
	{
		Write-Host "Looks like neither Chocolatey or WinGet are installed, make a selection:" -BackgroundColor DarkRed -ForegroundColor White
		Write-Host "G: Install WinGet"
		Write-Host "C: Install Chocolatey"
		Write-Host "Any other key: Skip python and git installation (only if you already have it installed)"
		$selection = Read-Host "Make a selection"
	}
}
# Installing Winget or Chocolatey

if ($selection -eq 'g') { install-winget }
elseif ($selection -eq 'c')
{
	install-choco
}

# Installing Python
if ($winget)
{
	Write-Host "Installing python..." -ForegroundColor Green
	winget install --silent --accept-package-agreements --accept-source-agreements Python.Python.3.12 Git.Git
}
elseif ($choco)
{
	Write-Host "Installing python..." -ForegroundColor Green
	choco install -y python git
}

# --- MAIN PROGRAM ---

Write-Host "Cloning mtkclient to your home directory" -BackgroundColor DarkGreen -ForegroundColor White
mkdir $env:UserProfile/mtkclient
git clone https://github.com/bkerler/mtkclient $env:USERPROFILE/mtkclient

Write-Host "Installing Requirements" -BackgroundColor DarkGreen -ForegroundColor White
Set-Location $env:UserProfile/mtkclient
pip3 install -r requirements.txt

Write-Host "Installing UsbDk" -BackgroundColor DarkGreen -ForegroundColor White
Invoke-WebRequest https://github.com/daynix/UsbDk/releases/download/v1.00-22/UsbDk_1.0.22_x64.msi -UseBasicParsing -OutFile usbdk.msi
Start-Process msiexec "/a usbdk.msi /passive"
Write-Host "Installed UsbDk" -BackgroundColor DarkGreen -ForegroundColor White

Write-Host "Installing WinFSP" -BackgroundColor DarkGreen -ForegroundColor White
Invoke-WebRequest https://github.com/winfsp/winfsp/releases/download/v2.0/winfsp-2.0.23075.msi -UseBasicParsing -OutFile winfsp.msi
Start-Process msiexec "/i winfsp.msi /passive"

# Driver install

$drvchoice = Read-Host "Do you want to install MTK USB drivers? Y/N"
if ($drvchoice -eq 'y')
{
	Invoke-WebRequest https://github.com/netzsworth/mtkclient-installer/raw/main/DriverInstall.exe -UseBasicParsing -OutFile mtkdriver.exe
	Start-Process mtkdriver.exe
}
Write-Host "-- Installation Finished --" -BackgroundColor DarkGreen -ForegroundColor White
Start-Process explorer $env:USERPROFILE\mtkclient
pause
