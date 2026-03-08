$ErrorActionPreference = "Stop";
$PSNativeCommandUseErrorActionPreference = $true;
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
  Brave
  BraveNotMy
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
  Firewall
  Reconcile
  LightsOut
  Desktop
  Desktop2
  Laptop
  Lenovo
  Vostro
  Scratchpad
  Cleanup
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
    [Configuration]::Firewall,
    [Configuration]::Brave,
    [Configuration]::Printer
  );

  $myDeviceConfigurations = $homeConfigurations + (
    [Configuration]::Dev,
    [Configuration]::MyDevice,
    [Configuration]::UacNoPrompt
  );

  $notMyDeviceConfigurations = $homeConfigurations + (
    [Configuration]::BraveNotMy,
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
  $env:PSModulePath = $localModulesPath + ";" + $env:PSModulePath;
  try {
    $configurationFiles | ForEach-Object { winget configure --verbose --accept-configuration-agreements --file $_; };
  }
  finally {
    $env:PSModulePath = $psModulePath;
  }
}

Export-ModuleMember -Function Install;
