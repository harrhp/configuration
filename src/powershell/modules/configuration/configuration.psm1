$ErrorActionPreference = "Stop";
Set-StrictMode -Version Latest;

enum Device {
  Desktop
  Desktop2
  Laptop
  Lenovo
  Vostro
  WorkLaptop
}

enum Configuration {
  Common
  CommonHome
  Activation
  Rdp
  Sshd
  SelfSignedCert
  Region
  UninstallBloat
  Dev
  MyDevice
  UacNoPrompt
  UacRequireCred
  LightsOut
  Desktop
  Desktop2
  Laptop
  Lenovo
  Vostro
}

function UpdateWinget {
  $wingetLatestVersion = Invoke-RestMethod https://api.github.com/repos/microsoft/winget-cli/releases/latest | Select-Object -ExpandProperty tag_name;
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

function TryFail {
  if ($LASTEXITCODE -ne 0) {
    throw "last command failed with $LASTEXITCODE";
  }
}

function Install {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [Device]
    $Device
  )

  UpdateWinget;

  $homeConfigurations = (
    [Configuration]::Common,
    [Configuration]::CommonHome,
    [Configuration]::Activation,
    [Configuration]::Rdp,
    [Configuration]::Sshd,
    [Configuration]::SelfSignedCert,
    [Configuration]::Region,
    [Configuration]::UninstallBloat
  );

  $myDeviceConfigurations = $homeConfigurations + (
    [Configuration]::Dev,
    [Configuration]::MyDevice,
    [Configuration]::UacNoPrompt
  );

  $notMyDeviceConfigurations = $homeConfigurations + (
    [Configuration]::UacRequireCred
  );

  $configurations = switch ($Device) {
    Desktop {
      (
        [Configuration]::Common,
        [Configuration]::Activation,
        [Configuration]::Rdp,
        [Configuration]::Sshd,
        [Configuration]::SelfSignedCert,
        [Configuration]::Region,
        [Configuration]::UninstallBloat,
        [Configuration]::Desktop,
        [Configuration]::UacNoPrompt
      )
    }
    Desktop2 { $myDeviceConfigurations + ([Configuration]::Desktop2, [Configuration]::LightsOut) }
    Laptop { $myDeviceConfigurations + [Configuration]::Laptop }
    Lenovo { $notMyDeviceConfigurations + [Configuration]::Lenovo }
    Vostro { $notMyDeviceConfigurations + [Configuration]::Vostro }
    WorkLaptop { [Configuration]::Common, [Configuration]::Dev }
  };

  Write-Host "determined configurations";
  $configurations | Write-Host;

  $configurationDirs = $configurations | ForEach-Object { switch ($_) {
      Common { "common" }
      CommonHome { "common-home" }
      Activation { "activation" }
      Rdp { "rdp" }
      Sshd { "sshd" }
      SelfSignedCert { "self-signed-cert" }
      Region { "region" }
      UninstallBloat { "uninstall-bloat" }
      Dev { "dev" }
      MyDevice { "my-device" }
      UacNoPrompt { "uac-no-prompt" }
      UacRequireCred { "uac-require-cred" }
      LightsOut { "lights-out-shortcut" }
      Desktop { "desktop" }
      Desktop2 { "desktop2" }
      Laptop { "laptop" }
      Lenovo { "lenovo" }
      Vostro { "vostro" }
    };
  };

  $dscRootPath = Join-Path $PWD "src";
  $configurationFiles = $configurationDirs | ForEach-Object { Join-Path $dscRootPath $_ | Join-Path -ChildPath "configuration.dsc.yaml" -Resolve };

  Write-Host "applying configuration from files";
  $configurationFiles | Write-Host;

  $localModulesPath = Join-Path $PWD "src/powershell/modules";
  $psModulePath = $env:PSModulePath;
  $env:PSModulePath = $localModulesPath + ";" + $env:PSModulePath;
  try {
    $configurationFiles | ForEach-Object { winget configure --accept-configuration-agreements --file $_; };
  }
  finally {
    $env:PSModulePath = $psModulePath;
  }

  if (Test-Path $PROFILE) {
    . $PROFILE;
  }
}

Export-ModuleMember -Function Install;
