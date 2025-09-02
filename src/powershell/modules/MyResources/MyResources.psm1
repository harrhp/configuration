$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

enum Ensure {
  Absent
  Present
}

function TryFail() {
  if ($LASTEXITCODE -ne 0) {
    throw "last command failed with $LASTEXITCODE";
  }
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
    return $state.Ensure -eq $this.Ensure `
      -and ($this.Ensure -eq [Ensure]::Absent `
        -or $state.DohTemplate -ne $this.DohTemplate `
        -and $state.AutoUpgrade -ne $this.AutoUpgrade);
  }

  [void] Set() {
    if (!$this.Test()) {
      if ($this.Ensure -eq [Ensure]::Present) {
        $state = $this.Get();
        $params = @{
          ServerAddress = $this.ServerAddress
          DohTemplate   = $this.DohTemplate
          AutoUpgrade   = $this.AutoUpgrade
          ErrorAction   = "Stop"
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
      $params = @{
        GeoId       = $this.GeoId
        ErrorAction = "Stop"
      };
      Set-WinHomeLocation @params;
    }
  }
}

[DscResource()]
class PrinterDriver {
  # Key required. Do not set.
  [DscProperty(Key)]
  [string]$SID

  [DscProperty()]
  [Ensure] $Ensure = [Ensure]::Present

  [DscProperty(Mandatory)]
  [string] $Name

  [PrinterDriver] Get() {
    $state = [PrinterDriver]::new();
    $state.Name = $this.Name;
    $printerDriver = Get-PrinterDriver -Name $this.Name -ErrorAction SilentlyContinue;
    $state.Ensure = switch ($null -eq $printerDriver) {
      $true { [Ensure]::Absent }
      $false { [Ensure]::Present }
    };

    return $state
  }

  [bool] Test() {
    $currentState = $this.Get();
    return $currentState.Ensure -eq $this.Ensure;
  }

  [void] Set() {
    if (!$this.Test()) {
      $params = @{
        Name = $this.Name
      };
      if ($this.Ensure -eq [Ensure]::Present) {
        Add-PrinterDriver @params;
      }
      else {
        Remove-PrinterDriver @params;
      }
    }
  }
}

[DscResource()]
class WindowsDriver {
  # Key required. Do not set.
  [DscProperty(Key)]
  [string]$SID

  [DscProperty()]
  [Ensure] $Ensure = [Ensure]::Present

  [DscProperty(Mandatory)]
  [string] $Version

  [DscProperty(Mandatory)]
  [string] $Inf

  [DscProperty()]
  [string] $Uri

  hidden [string] $DriverName

  [WindowsDriver] Get() {
    $state = [WindowsDriver]::new();
    $state.Version = $this.Version;
    $state.Inf = $this.Inf;

    $originalName = Split-Path -Path $this.Inf -Leaf;
    $output = pnputil.exe /enum-drivers /class Printer;
    TryFail;
    $windowsDriver = [regex]::Matches($output, "Published Name:\s*(.*?)\s+.*?Original Name:\s*(.*?)\s+.*?Driver Version:\s*.*? (.*?)\s")
    | ForEach-Object {
      @{
        DriverName   = $_.Groups[1].Value
        OriginalName = $_.Groups[2].Value
        Version      = $_.Groups[3].Value
      }
    }
    | Where-Object { $_.Version -eq $this.Version -and $_.OriginalName -eq $originalName };

    if ($windowsDriver) {
      $state.Ensure = [Ensure]::Present;
      $state.DriverName = $windowsDriver.DriverName;
    }
    else {
      $state.Ensure = [Ensure]::Absent;
    }

    return $state
  }

  [bool] Test() {
    $currentState = $this.Get();
    return $currentState.Ensure -eq $this.Ensure;
  }

  [void] Set() {
    if (!$this.Test()) {
      $state = $this.Get();
      if ($this.Ensure -eq [Ensure]::Present) {
        if ($this.Uri) {
          $temp = New-TemporaryFile;
          $tempDir = New-Item -ItemType Directory -Path $temp.FullName.TrimEnd(".tmp");
          $zip = [System.IO.Path]::ChangeExtension($temp, ".zip");
          Rename-Item $temp $zip;
          Start-BitsTransfer -Source $this.Uri -Destination $zip;
          Expand-Archive -Path $zip -DestinationPath $tempDir;
          $infPath = Join-Path $tempDir $this.Inf -Resolve;
        }
        else {
          $infPath = $this.Inf;
        }

        pnputil.exe /a $infPath;
        TryFail;
      }
      else {
        pnputil.exe /d $state.DriverName /f;
        TryFail;
      }
    }
  }
}

[DscResource()]
class PrinterPort {
  # Key required. Do not set.
  [DscProperty(Key)]
  [string]$SID

  [DscProperty()]
  [Ensure] $Ensure = [Ensure]::Present

  [DscProperty(Mandatory)]
  [string] $Name

  [DscProperty()]
  [string] $PrinterHostAddress

  [PrinterPort] Get() {
    $state = [PrinterPort]::new();
    $state.Name = $this.Name;
    $printerPort = Get-PrinterPort -Name $this.Name;
    if ($printerPort) {
      $state.Ensure = [Ensure]::Present;
      $state.PrinterHostAddress = $printerPort.PrinterHostAddress;
    }
    else {
      $state.Ensure = [Ensure]::Absent;
    }

    return $state
  }

  [bool] Test() {
    $currentState = $this.Get();
    return $currentState.Ensure -eq $this.Ensure -and ($this.Ensure -eq [Ensure]::Absent -or $currentState.PrinterHostAddress -eq $this.PrinterHostAddress);
  }

  [void] Set() {
    if (!$this.Test()) {
      $params = @{
        Name        = $this.Name
        ErrorAction = "Stop"
      };

      if ($this.Ensure -eq [Ensure]::Present) {
        $params["PrinterHostAddress"] = $this.PrinterHostAddress;
        Add-PrinterPort @params;
      }
      else {
        Remove-PrinterPort @params;
      }
    }
  }
}

[DscResource()]
class Printer {
  # Key required. Do not set.
  [DscProperty(Key)]
  [string]$SID

  [DscProperty()]
  [Ensure] $Ensure = [Ensure]::Present

  [DscProperty()]
  [string] $Name

  [DscProperty()]
  [string] $PortName

  [DscProperty()]
  [string] $DriverName

  [DscProperty()]
  [bool] $Shared

  [DscProperty()]
  [string] $ConnectionName

  [Printer] Get() {
    $state = [Printer]::new();
    if ($this.ConnectionName) {
      $state.ConnectionName = $this.ConnectionName;
      $effectiveName = $this.ConnectionName
    }
    else {
      $effectiveName = $this.Name;
    }

    $state.Name = $effectiveName;

    $printer = Get-Printer -Name $effectiveName;
    if ($printer) {
      $state.Ensure = [Ensure]::Present;
      $state.PortName = $printer.PortName;
      $state.DriverName = $printer.DriverName;
      $state.Shared = $printer.Shared;
    }
    else {
      $state.Ensure = [Ensure]::Absent;
    }

    return $state
  }

  [bool] Test() {
    $currentState = $this.Get();
    return $currentState.Ensure -eq $this.Ensure `
      -and ($currentState.Ensure -eq [Ensure]::Absent `
        -or $currentState.DriverName -eq $this.DriverName `
        -and $currentState.PortName -eq $this.PortName `
        -and $currentState.Shared -eq $this.Shared);
  }

  [void] Set() {
    if (!$this.Test()) {
      $state = $this.Get();
      $params = @{
        Name        = $state.Name
        ErrorAction = "Stop"
      };

      if ($this.Ensure -eq [Ensure]::Present) {
        if ($this.Name) {
          $params["DriverName"] = $this.DriverName;
          $params["PortName"] = $this.PortName;
          $params["Shared"] = $this.Shared;
        }

        if ($state.Ensure -eq [Ensure]::Absent) {
          if ($this.ConnectionName) {
            $params.Remove("Name");
            $params["ConnectionName"] = $this.ConnectionName;
          }

          Add-Printer @params;
        }
        else {
          Set-Printer @params;
        }
      }
      else {
        Remove-Printer @params;
      }
    }
  }
}

[DSCResource()]
class WslDistro {
  # Key required. Do not set.
  [DscProperty(Key)]
  [string]$SID

  [DscProperty()]
  [Ensure] $Ensure = [Ensure]::Present

  [DscProperty(Mandatory)]
  [string] $Distro

  [DscProperty()]
  [string] $InstallLocation

  [DscProperty()]
  [string] $File

  [WslDistro] Get() {
    $state = [WslDistro]::new();
    $state.Distro = $this.Distro;
    $exists = (wsl -l -q) -contains $this.Distro;
    if ($exists) {
      $state.Ensure = [Ensure]::Present;
      $state.InstallLocation = Get-ChildItem -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss" `
      | Where-Object { (Get-ItemPropertyValue -Path registry::$_ -Name DistributionName) -eq $this.Distro } `
      | Get-ItemPropertyValue -Name BasePath `
      | ForEach-Object { $_.TrimStart("\", "?") };
    }
    else {
      $state.Ensure = [Ensure]::Absent;
    }

    return $state;
  }

  [bool] Test() {
    $currentState = $this.Get()
    return $currentState.Ensure -eq $this.Ensure `
      -and ($currentState.Ensure -eq [Ensure]::Absent `
        -or $currentState.InstallLocation -eq (Resolve-Path $this.InstallLocation -ErrorAction SilentlyContinue));
  }

  [void] Set() {
    if (!$this.Test()) {
      if ($this.Ensure -eq [Ensure]::Present) {
        $currentState = $this.Get();
        if ($currentState.Ensure -eq [Ensure]::Absent) {
          $distroSourceFile = New-TemporaryFile;
          Start-BitsTransfer -Source $this.File -Destination $distroSourceFile;
          New-Item -ItemType Directory -Path $this.InstallLocation -Force;
          wsl --import $this.Distro (Resolve-Path $this.InstallLocation) $distroSourceFile
          TryFail;
          $result = wsl -d $this.Distro -u root cloud-init status --wait;
          if ($result -notmatch "status: done") {
            throw "cloud init failed";
          }
        }
        else {
          throw "can't change existing wsl distro";
        }
      }
      else {
        wsl --unregister $this.Distro;
        TryFail;
      }
    }
  }
}
