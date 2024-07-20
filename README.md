# How to use

Turn off UAC manually to avoid notifications during not elevated pass. Not elevated pass needed to create files in user home with correct owner

1. In not elevated powershell session

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

2. Repeat 1 in elevated session
3. Reboot
