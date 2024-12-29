$ErrorActionPreference = "Stop";
Set-StrictMode -Version Latest;

enum Device {
  Desktop = 1
  Desktop2
  Laptop
  Lenovo
  Vostro
  WorkLaptop
}

enum Configuration {
  BasePackages = 1
  BaseHomePackages
  Sshd
  SelfSignedCert
  WindowsSettings
  Edge
  Antivirus
  Printer
  UninstallBloat
  Dev
  MyDevice
  UacNoPrompt
  UacRequireCred
  Reconcile
  LightsOut
  Desktop
  Desktop2
  Laptop
  Lenovo
  Vostro
  Scratchpad
}

function UpdateWinget {
  $wingetLatestVersion = (Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest).tag_name;
  $wingetActualVersion = winget --version;
  TryFail;
  if ($wingetActualVersion -lt $wingetLatestVersion) {
    $packageUris = (
      "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx",
      "https://aka.ms/getwinget"
    );

    foreach ($packageUri in $packageUris) {
      $packageMsix = New-TemporaryFile;
      Start-BitsTransfer -Source $packageUri -Destination $packageMsix;
      Add-AppxPackage $packageMsix -ForceApplicationShutdown;
      Remove-Item $packageMsix -ErrorAction SilentlyContinue;
    }
  }

  Write-Host "winget is up to date";
}

function MakeLocalModulesAvailable {
  param (
    [Parameter(Mandatory)]
    [string]
    $localModulesPath
  )

  if ([Environment]::OSVersion.Version -lt "10.0.22000") {
    $wingetModulesPath = Join-Path $env:LOCALAPPDATA "Microsoft/WinGet/Configuration/Modules" -Resolve;
    $modules = ("FileContentDsc", "MyResources");
    $modulePaths = $modules | ForEach-Object {
      [PSCustomObject]@{
        src  = Join-Path $localModulesPath $_ -Resolve
        dest = Join-Path $wingetModulesPath $_
      }
    }
    Write-Host "fixing local modules for win10";
    $modulePaths | Format-Table src, dest -Wrap -AutoSize;
    $modulePaths | ForEach-Object { Robocopy.exe $_.src $_.dest /MIR; };
  }
  else {
    $env:PSModulePath = $localModulesPath + ";" + $env:PSModulePath;
    Write-Host "PSModulePath modified" $env:PSModulePath
  }
}

function TryFail {
  if ($LASTEXITCODE -ne 0) {
    throw "last command failed with $LASTEXITCODE";
  }
}

function Install {
  [CmdletBinding(DefaultParameterSetName = "Device")]
  param (
    [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Device")]
    [Device]
    $Device,
    [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Generic")]
    [Configuration[]]
    $Configurations,
    [Parameter()]
    [string]
    $RepoRootPath = $PWD
  )

  $homeBaseConfigurations = (
    [Configuration]::SelfSignedCert,
    [Configuration]::WindowsSettings,
    [Configuration]::Edge,
    [Configuration]::Antivirus,
    [Configuration]::BasePackages,
    [Configuration]::Sshd,
    [Configuration]::UninstallBloat,
    [Configuration]::Reconcile
  );

  $homeConfigurations = $homeBaseConfigurations + (
    [Configuration]::BaseHomePackages,
    [Configuration]::Printer
  );

  $myDeviceConfigurations = $homeConfigurations + (
    [Configuration]::Dev,
    [Configuration]::MyDevice,
    [Configuration]::UacNoPrompt
  );

  $notMyDeviceConfigurations = $homeConfigurations + (
    [Configuration]::UacRequireCred
  );

  if ($Configurations) {
    $effectiveConfigurations = $Configurations;
  }
  else {
    $effectiveConfigurations = switch ($Device) {
      Desktop { $homeBaseConfigurations + [Configuration]::Desktop }
      Desktop2 { $myDeviceConfigurations + ([Configuration]::Desktop2, [Configuration]::LightsOut) }
      Laptop { $myDeviceConfigurations + [Configuration]::Laptop }
      Lenovo { $notMyDeviceConfigurations + [Configuration]::Lenovo }
      Vostro { $notMyDeviceConfigurations + [Configuration]::Vostro }
      WorkLaptop { [Configuration]::BasePackages, [Configuration]::Dev }
    };
  }

  Write-Host "determined effectiveConfigurations";
  $effectiveConfigurations | Write-Host;

  $configurationDirs = $effectiveConfigurations | ForEach-Object { $_.ToString() -creplace "([a-z])([A-Z])", '$1-$2' };

  $dscRootPath = Join-Path $RepoRootPath "src";
  $configurationFiles = $configurationDirs | ForEach-Object { Join-Path $dscRootPath $_ | Join-Path -ChildPath "configuration.dsc.yaml" -Resolve };

  Write-Host "applying configuration from files";
  $configurationFiles | Write-Host;

  $localModulesPath = Join-Path $RepoRootPath "src/powershell/modules";

  $psModulePath = $env:PSModulePath;
  MakeLocalModulesAvailable $localModulesPath;
  UpdateWinget;

  try {
    $configurationFiles | ForEach-Object { winget configure --verbose --accept-configuration-agreements --file $_; };
  }
  finally {
    $env:PSModulePath = $psModulePath;
  }

  if (Test-Path $PROFILE) {
    . $PROFILE;
  }
}

Export-ModuleMember -Function Install;
