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

		[void][reflection.assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')
		$server=new-object Microsoft.SqlServer.Management.Smo.Server($env:SqlInstance)

        # [ValidateSet[(...)]
        $databaseNames = @()
		foreach ($database in $server.Databases) {
			$databaseNames += $database.name
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
		[void][reflection.assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')
		$server = new-object Microsoft.SqlServer.Management.Smo.Server($env:SqlInstance)
		$db = $server.Databases[$PSBoundParameters.dbName]
		$dbname = $db.Name
		$formattedDate = get-date -format yyyyMMddHHmmss
		$backupTarget = $env:SqlBackupDir + $dbname + "_" + $formattedDate + ".bak"

		[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended')
		$dbBackup = new-object Microsoft.SqlServer.Management.Smo.Backup
		$dbBackup.Action = 'Database'
		$dbBackup.BackupSetDescription = "Full backup of " + $dbname
		$dbBackup.BackupSetName = $dbname + " Backup"
		$dbBackup.Database = $dbname
		$dbBackup.MediaDescription = "Disk"
		$dbBackup.Devices.AddDevice($backupTarget, 'File')

		Write-Host "Backing up $dbname to $backupTarget"
		$dbBackup.SqlBackup($server)
		Write-Host "Done."
	}
}
