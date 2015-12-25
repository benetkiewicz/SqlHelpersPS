# Sql Helpers for PowerShell
This PowerShell module is designed to assist you with repeating backup and restore database operations. It provides `tab` completion for database name and configurable instance name and backup directory.

## Installation
```powershell
> Import-Module .\SqlHelpers.psd1
```
## Configuration
* set `$env:SqlInstance` for your current session or in your profile, like that:
```powershell
$env:SqlInstance = 'LOCALHOST\SQL2008R2'
``` 

## Basic Usage
```powershell
> New-SqlBackup -dbName AdventureWorks
> Restore-SqlBackup -backupPath 'c:\backups\AdventureWorks_20151224203918.bak'
```

## Advanced usage
* There's `tab` completion support for `-dbName` param. No need to exactly remember or copy&paste anything! 
* `New-SqlBackup` sets `$env:lastSqlBackup` variable, which is a default `-backupPath` for `Restore-SqlBackup`. So using `Restore-SqlBackup` without any parameters will use your last backup.
* Note that `Restore-SqlBackup` runs in replace mode.