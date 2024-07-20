$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

enum Ensure {
  Absent
  Present
}

[DSCResource()]
class File {
  # Key required. Do not set.
  [DscProperty(Key)]
  [string]$SID

  [DscProperty()]
  [Ensure] $Ensure = [Ensure]::Present

  [DscProperty(Mandatory)]
  [string] $DestinationPath

  [DscProperty()]
  [string] $SourcePath

  [File] Get() {
    $state = [File]::new();
    if ($this.SourcePath) {
      $sourceContent = Get-Content -Path $this.SourcePath -Raw;
      $destinationContent = Get-Content -Path $this.DestinationPath -Raw -ErrorAction SilentlyContinue;
      $test = $sourceContent -eq $destinationContent;
    }
    else {
      $test = Test-Path -Path $this.DestinationPath;
    }

    if ($test) {
      $state.Ensure = [Ensure]::Present;
    }
    else {
      $state.Ensure = [Ensure]::Absent;
    }

    return $state;
  }

  [bool] Test() {
    $state = $this.Get()
    return $state.Ensure -eq $this.Ensure;
  }

  [void] Set() {
    if (!$this.Test()) {
      if ($this.Ensure -eq [Ensure]::Present) {
        $destinationDirPath = Split-Path $this.DestinationPath -Parent;
        if (!(Test-Path $destinationDirPath)) {
          New-Item -Path $destinationDirPath -ItemType Directory;
        }

        $sourceContent = Get-Content -Path $this.SourcePath -Raw;
        Set-Content -Path $this.DestinationPath -Value $sourceContent -NoNewLine;
      }
      else {
        Remove-Item -Path $this.DestinationPath;
      }
    }
  }
}

[DSCResource()]
class DohServerTemplate {
  # Key required. Do not set.
  [DscProperty(Key)]
  [string]$SID

  [DscProperty()]
  [Ensure] $Ensure = [Ensure]::Present

  [DscProperty(Mandatory)]
  [string] $ServerAddress

  [DscProperty(Mandatory)]
  [string] $DohTemplate

  [DscProperty()]
  [bool] $AutoUpgrade

  [DohServerTemplate] Get() {
    $state = [DohServerTemplate]::new();

    $dohState = Get-DNSClientDohServerAddress -ServerAddress $this.ServerAddress;
    if ($dohState) {
      $state.Ensure = [Ensure]::Present;
      $state.ServerAddress = $dohState.ServerAddress
      $state.DohTemplate = $dohState.DohTemplate;
      $state.AutoUpgrade = $dohState.AutoUpgrade;
    }
    else {
      $state.Ensure = [Ensure]::Absent;
    }

    return $state;
  }

  [bool] Test() {
    if ([Environment]::OSVersion.Version -lt "10.0.22000") {
      return $true;
    }

    $state = $this.Get()
    if ($state.Ensure -ne $this.Ensure) {
      return $false;
    }

    if ($this.Ensure -eq [Ensure]::Present) {
      if ($state.DohTemplate -ne $this.DohTemplate) {
        return $false;
      }

      if ($state.AutoUpgrade -ne $this.AutoUpgrade) {
        return $false;
      }
    }

    return $true;
  }

  [void] Set() {
    if (!$this.Test()) {
      $isAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544");
      if (!$isAdmin) {
        throw "must run as admin"
      }

      if ($this.Ensure -eq [Ensure]::Present) {
        $state = $this.Get();
        $params = @{
          ServerAddress = $this.ServerAddress
          DohTemplate   = $this.DohTemplate
          AutoUpgrade   = $this.AutoUpgrade
        }

        if ($state.Ensure -eq [Ensure]::Absent) {
          Add-DNSClientDohServerAddress @params;
        }
        else {
          Set-DNSClientDohServerAddress @params;
        }
      }
      else {
        Remove-DNSClientDohServerAddress -ServerAddress $this.ServerAddress;
      }
    }
  }
}

[DSCResource()]
class Culture {
  # Key required. Do not set.
  [DscProperty(Key)]
  [string]$SID

  [DscProperty()]
  [Ensure] $Ensure = [Ensure]::Present

  [DscProperty()]
  [string] $Name

  [Culture] Get() {
    $state = [Culture]::new();
    $state.Name = (Get-Culture).Name;
    $state.Ensure = switch (Get-WinCultureFromLanguageListOptOut) {
      $true { [Ensure]::Present }
      $false { [Ensure]::Absent }
    }

    return $state;
  }

  [bool] Test() {
    $state = $this.Get()
    return $state.Ensure -eq $this.Ensure -and ($this.Ensure -eq [Ensure]::Absent -or $state.Name -eq $this.Name);
  }

  [void] Set() {
    if (!$this.Test()) {
      $cultureFromLanguageListOptOut = $this.Ensure -eq [Ensure]::Present;
      $cultureName = switch ($this.Ensure) {
        Present { $this.Name }
        Absent { (Get-UICulture).Name }
      }
      Set-Culture $cultureName;
      Set-WinCultureFromLanguageListOptOut -OptOut $cultureFromLanguageListOptOut;
    }
  }
}

[DSCResource()]
class WinHomeLocation {
  # Key required. Do not set.
  [DscProperty(Key)]
  [string]$SID

  [DscProperty(Mandatory)]
  [string] $GeoId

  [WinHomeLocation] Get() {
    $state = [WinHomeLocation]::new();
    $state.GeoId = (Get-WinHomeLocation).GeoId;
    return $state;
  }

  [bool] Test() {
    $state = $this.Get()
    return $state.GeoId -eq $this.GeoId;
  }

  [void] Set() {
    if (!$this.Test()) {
      $params = @{ GeoId = $this.GeoId };
      Set-WinHomeLocation @params;
    }
  }
}
