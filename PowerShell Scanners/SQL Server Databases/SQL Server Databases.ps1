[CmdletBinding()]
param (
    [string]$Instance = ".\SQLExpress"
)

$query = @"
    SELECT 
        database_id
        ,name
        ,state_desc
        ,suser_sname(owner_sid)
        ,create_date
        ,compatibility_level
        ,collation_name
        ,recovery_model_desc
        ,physical_database_name
    FROM 
        master.sys.databases
    WHERE
        name NOT IN ('master', 'model', 'msdb', 'tempdb')

"@

$dbs = (sqlcmd -S "$Instance" -s "|" -E -Q $query) -split "`r`n"

for($i = 2; $i -lt $dbs.Count - 2; $i++) {
    
    $tokens = $dbs[$i] -split "\|"

    if ($tokens.Count -eq 9) {

        [PSCustomObject]@{
            'Id' = [int]$tokens[0].Trim()
            'Name' = $tokens[1].Trim()
            'Status' = $tokens[2].Trim()
            'Owner' = $tokens[3].Trim()
            'CreateDate' = [DateTime]$tokens[4].Trim()
            'CompatLevel' = [int]$tokens[5].Trim()
            'Collation' = $tokens[6].Trim()
            'RecoveryModel' = $tokens[7].Trim()
            'PhysicalDbName' = $tokens[8].Trim()
        }
    }
}