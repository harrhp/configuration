$ErrorActionPreference = "Stop";

function TryFail {
  if ($LASTEXITCODE -ne 0) {
    throw "last command failed with $LASTEXITCODE";
  }
}

$isAdmin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544");
$gitDirPath = Join-Path $HOME "git";
$repoDirPath = Join-Path $gitDirPath "configuration";

if (!(Test-Path $gitDirPath) -and ![System.Security.Principal.WindowsIdentity]::GetCurrent().IsSystem -and $isAdmin) {
  throw "run first pass not as admin"
}

if (!$isAdmin -and (Get-Command git -ErrorAction SilentlyContinue)) {
  New-Item -Path $repoDirPath -ItemType Directory -Force;
  git -C $repoDirPath init;
  git -C $repoDirPath remote add origin https://github.com/harrhp/configuration.git;
  git -C $repoDirPath fetch origin main;
  git -C $repoDirPath reset origin/main --hard;
  TryFail;
}
else {
  $repoZipUrl = "https://api.github.com/repos/harrhp/configuration/zipball/HEAD";
  $tempFilePath = New-TemporaryFile;
  $tempZipPath = [System.IO.Path]::ChangeExtension($tempFilePath, ".zip");

  Rename-Item -Path $tempFilePath -NewName $tempZipPath;

  $tempDirName = [io.path]::GetFileNameWithoutExtension($tempZipPath);
  $tempDirPath = Join-Path (Split-Path $tempZipPath -Parent) $tempDirName;

  Invoke-WebRequest -Uri $repoZipUrl -OutFile $tempZipPath;
  Expand-Archive -Path $tempZipPath -DestinationPath $tempDirPath;

  $repoTempDirPath = Join-Path $tempDirPath * -Resolve;
  Robocopy.exe $repoTempDirPath $repoDirPath /MIR;
  Remove-Item -Path $tempZipPath, $tempDirPath -Recurse -Force;
}

$configurationModulePath = Join-Path $repoDirPath "src/powershell/modules/configuration" -Resolve;
Import-Module $configurationModulePath -Force;

Install -RepoRootPath $repoDirPath @args;
