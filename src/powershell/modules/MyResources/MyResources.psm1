$ErrorActionPreference = "Stop"
#Set-StrictMode -Version Latest

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

  [DscProperty()]
  [string] $DestinationPath

  [DscProperty()]
  [string] $SourcePath

  [File] Get() {
    return @{
      Ensure = $this.Ensure
    }
  }

  [bool] Test() {
    $currentState = $this.Get()
    if ($currentState.Ensure -eq [Ensure]::Present) {
      $destinationContent = Get-Content -Path $this.DestinationPath -Raw -ErrorAction SilentlyContinue;
      $sourceContent = Get-Content -Path $this.SourcePath -Raw -ErrorAction SilentlyContinue;
      $test = $sourceContent -eq $destinationContent;
      return $test;
    }
    else {
      return !(Test-Path -Path $this.DestinationPath);
    }
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
