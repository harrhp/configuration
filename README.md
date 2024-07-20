# How to use
```PowerShell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process -Force
irm https://raw.githubusercontent.com/harrhp/configuration/HEAD/install.ps1 | iex
```

```
& ([ScriptBlock]::Create((Invoke-RestMethod https://raw.githubusercontent.com/harrhp/configuration/HEAD/install.ps1))) -Device pcname
```
