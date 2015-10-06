########################################################################################### 
# Name         : Export-SQLTable2CSV
# Author       : Pramod Singla (Ecova DBAs) 17th Sept 2015
# Purpose      : It exports SQL table data into CSV.
# Test String  : Export-SQLTable2CSV -SQLServerName "localhost" -DBName "master" -SelectQuery "Select * from sysprocesses" -CSVFilePath "E:\" .
#                If csv file is not specified then present working dir is used
# Requires   : Script is developed and tested on PS vesion 4
########################################################################################## 
##Paramter setting
FUNCTION Export-SQLTable2CSV {
 [CmdletBinding()]
PARAM
(
    [Parameter(Mandatory=$True)]
	[string]$SQLServerName ,
    [Parameter(Mandatory=$True)]
	[string]$DBName,
    [string]$SelectQuery,
    [string]$CSVFilePath,
    [String]$CSVFileName="test.csv",
    [string]$CSVDelimiter = "~" 
)
#############Start TRY (Entry Point)####################
TRY
{
##Starting watch
$elapsed = [System.Diagnostics.Stopwatch]::StartNew()  
#Get current execution\script path
$ScriptDir = Get-Location

#If csv path is null then assign current dir
if ([string]::IsNullOrEmpty($CSVFilePath)){

$CSVFilePath=$ScriptDir
}



#setting the CSV file full name
IF ($CSVFilePath.Substring($CSVFilePath.Length-1) -ne "\"){
    $CSVFilePath =$CSVFilePath +"\"
    }
$CSVFileFullName=$CSVFilePath+$CSVFileName

#Setting a new database connection
$ConnectionString = "Data Source=$SQLServerName; Database=$DBName; Trusted_Connection=True;";
$sqlConn = New-Object System.Data.SqlClient.SqlConnection $ConnectionString 

#Set a write connection to CSV file
$StreamWriter = New-Object System.IO.StreamWriter $CSVFileFullName

#Set command to pull data from the datbase table
$sqlCmd = New-Object System.Data.SqlClient.SqlCommand 
$sqlCmd.Connection = $sqlConn 
$sqlCmd.CommandText = $SelectQuery 
$sqlConn.Open(); 


#Read data from data table
$Reader = $sqlCmd.ExecuteReader();

#Initialze the array the hold the values 
$Array = @() 
FOR ( $Counter = 0 ; $Counter -lt $Reader.FieldCount; $Counter++ ) { $Array += @($Counter) } 

# Write Header 
$StreamWriter.Write($Reader.GetName(0)) 
FOR ( $Counter = 1; $Counter -lt $Reader.FieldCount; $Counter ++) 
{ $StreamWriter.Write($("~" + $Reader.GetName($Counter))) } 
$StreamWriter.WriteLine("") 

#Write  Data to CSV
WHILE ($Reader.Read()) { 
$RowCounter++; 
# get the values;
    $fieldCount = $Reader.GetValues($Array); 
    $NewRow = [string]::Join("~", $Array);
    $StreamWriter.WriteLine($NewRow) 

      if (($RowCounter % 50000) -eq 0) {        
        Write-Host "$RowCounter rows have been exported in $($elapsed.Elapsed.ToString())." }
        
    
    }    
}
############Start Catch#############
CATCH [Exception]
    {     
        $output = "Failure:`n`n " + $_.Exception        
        throw $output  
        
    }
###########Start finally#############
FINALLY{
# Clean Up
if ($sqlConn.State -eq 'Open')
    {
        $sqlConn.close();
   }

  $Reader.Close(); 

  $StreamWriter.Close(); 
 
}
#######################
}
###############END of Function################
