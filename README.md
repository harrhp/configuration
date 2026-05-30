# How to use

```PowerShell
irm https://raw.githubusercontent.com/harrhp/configuration/HEAD/install.ps1 | iex
```
or
```
& ([ScriptBlock]::Create((Invoke-RestMethod https://raw.githubusercontent.com/harrhp/configuration/HEAD/install.ps1))) -Device pcname
```
