# How to use

1. Run `winget install --id Microsoft.VCRedist.2015+.x64 -e` to support `securityContext: elevated`
2. In powershell session

```PowerShell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
```
```PowerShell
irm https://raw.githubusercontent.com/harrhp/configuration/HEAD/install.ps1 | iex
```
or
```
& ([ScriptBlock]::Create((Invoke-RestMethod https://raw.githubusercontent.com/harrhp/configuration/HEAD/install.ps1))) -Device pcname
```
3. Reboot
