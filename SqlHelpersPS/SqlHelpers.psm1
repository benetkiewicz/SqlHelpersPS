<#
	My Function
#>
function New-SqlBackup {
	[CmdletBinding()]
    Param ()
    DynamicParam {
        # The "modules" param
        $dbNameAttributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]

        # [parameter(mandatory=..., )]
        $dbNameParameterAttribute = new-object System.Management.Automation.ParameterAttribute
        $dbNameParameterAttribute.Mandatory = $true
        $dbNameParameterAttribute.HelpMessage = "Enter one or more database names, separated by commas"
        $dbNameAttributeCollection.Add($dbNameParameterAttribute)    

		[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')
        [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended')
        [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") 

        try {        
            $connection = new-object Microsoft.SqlServer.Management.Common.ServerConnection($env:SqlInstance)
            $connection.ConnectTimeout = 2
            $server=new-object Microsoft.SqlServer.Management.Smo.Server($connection)

            # [ValidateSet[(...)]
            $databaseNames = @()
            foreach ($database in $server.Databases) {
                $databaseNames += $database.name
            }
        } 
        catch {
            Write-Host "Error while listing available databases, probably DB is down or not properly configured SqlInstance variable." -ForegroundColor "Red"
            break
        }
		        
        $dbNameValidateSetAttribute = New-Object -type System.Management.Automation.ValidateSetAttribute($databaseNames)
        $dbNameAttributeCollection.Add($dbNameValidateSetAttribute)

        # Remaining boilerplate
        $modulesRuntimeDefinedParam = new-object -Type System.Management.Automation.RuntimeDefinedParameter("dbName", [String[]], $dbNameAttributeCollection)
        $paramDictionary = new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
        $paramDictionary.Add("dbName", $modulesRuntimeDefinedParam)

        return $paramDictionary
    }

	Process {
		[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')
        [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended')
        [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") 
        try { 
            $connection = new-object Microsoft.SqlServer.Management.Common.ServerConnection($env:SqlInstance)
            $connection.ConnectTimeout = 2
            $server=new-object Microsoft.SqlServer.Management.Smo.Server($connection)
            $db = $server.Databases[$PSBoundParameters.dbName]
        } 
        catch {
            Write-Host "Error while trying to back up database, probably DB is down or not properly configured SqlInstance variable." -ForegroundColor "Red"
            break;
        }
        
		$dbname = $db.Name
		$formattedDate = get-date -format yyyyMMddHHmmss
		$backupTarget = $env:SqlBackupDir + $dbname + "_" + $formattedDate + ".bak"

		$dbBackup = new-object Microsoft.SqlServer.Management.Smo.Backup
		$dbBackup.Action = 'Database'
		$dbBackup.BackupSetDescription = "Full backup of " + $dbname
		$dbBackup.BackupSetName = $dbname + " Backup"
		$dbBackup.Database = $dbname
		$dbBackup.MediaDescription = "Disk"
		$dbBackup.Devices.AddDevice($backupTarget, 'File')

		Write-Host "Backing up $dbname to $backupTarget"
		$dbBackup.SqlBackup($server)
		$env:lastSqlBackup = $backupTarget
		Write-Host "Done."
	}
}

function Restore-SqlBackup {
	[CmdletBinding()]
	Param(
        [parameter(Mandatory=$false)]
        [alias("bp")]
        $backupPath = $env:lastSqlBackup
    )
	Process {
		[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')
        [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended')
        [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")
        
        $connection = new-object Microsoft.SqlServer.Management.Common.ServerConnection($env:SqlInstance)
        $connection.ConnectTimeout = 2
        $server=new-object Microsoft.SqlServer.Management.Smo.Server($connection)
		$restore = new-object Microsoft.SqlServer.Management.Smo.Restore
		$backupDeviceItem = new-object Microsoft.SqlServer.Management.Smo.BackupDeviceItem($backupPath, 'File')
		$restore.Devices.Add($backupDeviceItem)
		$restore.NoRecovery = $false;
		$restore.ReplaceDatabase = $true;
		$restore.Action = "Database"
		
        try {
            $restoreProps = $restore.ReadFileList($server)
            $restoredName = $restoreProps.Rows[0]["LogicalName"]
            Write-Host "Restoring: $restoredName"
            $restore.Database = $restoredName;
            $restore.SqlRestore($server)
        } 
        catch {
            Write-Host "Error while trying to restore database, probably DB is down or not properly configured SqlInstance variable." -ForegroundColor "Red"
            break
        }
		Write-Host "Done."
	}
}
