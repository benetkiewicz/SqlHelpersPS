<#
	My Function
#>
function Get-Function {
	[CmdletBinding()]
    Param ()
    DynamicParam {
        #
        # The "modules" param
        #
        $dbNameAttributeCollection = new-object -Type System.Collections.ObjectModel.Collection[System.Attribute]

        # [parameter(mandatory=...,
        #     ...
        # )]
        $dbNameParameterAttribute = new-object System.Management.Automation.ParameterAttribute
        $dbNameParameterAttribute.Mandatory = $true
        $dbNameParameterAttribute.HelpMessage = "Enter one or more database names, separated by commas"
        $dbNameAttributeCollection.Add($dbNameParameterAttribute)    

		[void][reflection.assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')
		$server=new-object Microsoft.SqlServer.Management.Smo.Server('LOCALHOST\LOCAL2008')

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
	PROCESS {
		$name = $PSBoundParameters.dbName
		Write-Host $name
		[void][reflection.assembly]::LoadWithPartialName('Microsoft.SqlServer.Smo')
		$svr=new-object Microsoft.SqlServer.Management.Smo.Server('LOCALHOST\LOCAL2008')
		$db = $svr.Databases[$name]
		$dbname = $db.Name
		$dt = get-date -format yyyyMMddHHmmss
		
		[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended')
		$dbbk = new-object Microsoft.SqlServer.Management.Smo.Backup
		$dbbk.Action = 'Database'
		$dbbk.BackupSetDescription = "Full backup of " + $dbname
		$dbbk.BackupSetName = $dbname + " Backup"
		$dbbk.Database = $dbname
		$dbbk.MediaDescription = "Disk"
		$dbbk.Devices.AddDevice("c:\temp\" + $dbname + "_db_" + $dt + ".bak", 'File')
		$dbbk.SqlBackup($svr)
	}
}
