$ErrorActionPreference = "Stop";

$repoUrl = "https://api.github.com/repos/harrhp/configuration/zipball/HEAD";
$tempFilePath = New-TemporaryFile;
$tempZipPath = [System.IO.Path]::ChangeExtension($tempFilePath, ".zip");
$tempDirName = [io.path]::GetFileNameWithoutExtension($tempZipPath);
$tempDirPath = Join-Path (Split-Path $tempZipPath -Parent) $tempDirName;

Invoke-WebRequest -Uri $repoUrl -OutFile $tempZipPath;
Expand-Archive -Path $tempZipPath -DestinationPath $tempDirPath;

$repoDirPath = Join-Path $tempDirPath * -Resolve;
Push-Location $repoDirPath;

$configurationModulePath = Join-Path $repoDirPath "src/powershell/modules/configuration";
Import-Module $configurationModulePath -Force;

try {
  Install @args;
}
finally {
  Pop-Location;
}

