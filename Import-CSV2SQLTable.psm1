########################################################################################### 
# Name         : Import-CSV2SQLTable
# Author       : Pramod Singla (Ecova DBAs) 17th Sept 2015
# Purpose      : It imports CSV into SQL table.
# Test String  : Import-CSV2SQLTable -SQLServerName "localhost" -DBName "DbtsTest" -TableName "P" -CSVFilePath "E:\My_Work\Subset_EDGEDW\CSVFileFolder" -CSVFileName "P.csv"
# Requires     : Script is developed and tested on PS vesion 4
#             :Import-module .\Import-CSV2SQLTable -force
########################################################################################## 
##Paramter setting
FUNCTION Import-CSV2SQLTable {
 [CmdletBinding()]
PARAM
(
	[string]$SQLServerName ,
	[string]$DBName,
    [string]$TableName,
    [string]$CSVFilePath = "C:\",
    [String]$CSVFileName="test.csv",
    [string]$CSVDelimiter = "~" ,
    [bool]$FirstRowColumnNames = $true ,
    [int]$BatchSize = 50000  # 50k worked fastest and kept memory usage to a minimum
)
##Load Assemblies
$elapsed = [System.Diagnostics.Stopwatch]::StartNew()  
[void][Reflection.Assembly]::LoadWithPartialName("System.Data") 
[void][Reflection.Assembly]::LoadWithPartialName("System.Data.SqlClient") 

############# Start TRY (Entry Point) ####################
TRY
{
#setting the CSV file full name
IF ($CSVFilePath.Substring($CSVFilePath.Length-1) -ne "\"){
    $CSVFilePath =$CSVFilePath +"\"
    }
$CSVFileFullName=$CSVFilePath+$CSVFileName

################### MAIN ###################  
# Build the sqlbulkcopy connection, and set the timeout to infinite 
$ConnectionString = "Data Source=$SQLServerName;Integrated Security=true;Initial Catalog=$DBName;" 
$BulkCopy = New-Object Data.SqlClient.SqlBulkCopy($ConnectionString, [System.Data.SqlClient.SqlBulkCopyOptions]::TableLock) 
$BulkCopy.DestinationTableName = $TableName 
$BulkCopy.bulkcopyTimeout = 0 
$BulkCopy.batchsize = $BatchSize 
  
# Create the datatable, and autogenerate the columns. 
$DataTable = New-Object System.Data.DataTable 
  
# Open the text file from disk 
$Reader = New-Object System.IO.StreamReader($CSVFileFullName) 
$Columns = (Get-Content $CSVFileFullName -First 1).Split($CSVDelimiter) 

##get Column Names from first line
if ($FirstRowColumnNames -eq $true) { 
    $null = $Reader.readLine() 
    } 
 
#create data table with cloumn names read from first line  
FOREACH ($Column in $Columns) {  
    $null = $DataTable.Columns.Add() 
} 
  
# Read in the data, line by line 
while (($Line = $Reader.ReadLine()) -ne $null)  { 
    
    $null = $DataTable.Rows.Add($Line.Split($CSVDelimiter))  
    $RowCounter++; 

    if (($RowCounter % $BatchSize) -eq 0) {  
        $BulkCopy.WriteToServer($DataTable)  
        Write-Host "$RowCounter rows have been inserted in $($elapsed.Elapsed.ToString())." 
        $DataTable.Clear()  
    }  
}  
  
# Add in all the remaining rows since the last clear 
if($DataTable.Rows.Count -gt 0) { 
    $BulkCopy.WriteToServer($DataTable) 
    $DataTable.Clear() 
} 
  

Write-Host "Script complete. $RowCounter rows have been inserted into the database." 
Write-Host "Total Elapsed Time: $($elapsed.Elapsed.ToString())" 

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
    $Reader.Close();    
    $BulkCopy.Close(); 
    # Sometimes the Garbage Collector takes too long to clear the huge datatable. 
    [System.GC]::Collect()
    }
}
