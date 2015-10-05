﻿########################################################################################### 
# Name         : Subset-Export2CSV
# Author       : Pramod Singla (Ecova DBAs) 17th Sept 2015
# Purpose      : It exports SQL table query data into CSV.
# Test String  : .\Subset-Export2CSV.ps1  -ClientKey 2 
#              : .\Subset-Export2CSV.ps1  -DBName "master" -ClientKey 2  -CSVFilePath E:\My_Work\Subset_EDGEDW\CSVFileFolder -FromDate "9-10-2014" -ToDate "10-10-2015"
# Mandatory Parameters: atleast Pass value of ClientKey or (FromDate and ToDate)
# Requires     : Script is developed and tested on PS vesion 4, a XML file of following format
#              <!-- TableList.xml -->
#              <DB SQLServerName="localhost" DBName="EdgeDW">
#              	<Table TableName="P">
#              		<ClientKeyColumnName>ClientKey</ClientKeyColumnName>
#              		<DateRangeColumnName>crdt</DateRangeColumnName>
#              		<SelectQuery>SELECT * FROM p (nolock)</SelectQuery>
#              	</Table>
#              </DB>
########################################################################################## 
########## Paramter setting ##########################
PARAM
(   
    [string]$SQLServerName ="localhost",
	[string]$DBName ,
    [string]$ClientKey,
    [string]$FromDate,  
    [string]$ToDate,  
    [string]$CSVFilePath     
)
#### Start TRY (Entry Point) #################
TRY
{
#checking paramter values
IF([string]::IsNullOrEmpty($ClientKey) -and ([string]::IsNullOrEmpty($FromDate) -or [string]::IsNullOrEmpty($ToDate))) {
"Must specify clientkey or the date range"
"Exiting....."
exit
}
################## Setting Variables ###################
$CSVDelimiter = "~" 
#$SQLServerName=$null 
#$DBName=$null

#Get current execution\script path
$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path

#Read the table list to subset
[xml]$XmlSubsetTableList = Get-Content -Path "$ScriptDir\SubsetTableList.xml"

#Set the SQL server and DBName
#$SQLServerName=$XmlSubsetTableList.DB.SQLServerName
#$DBName=$XmlSubsetTableList.DB.DBName

#Check if servername or DB name is valid and exit if it is not
IF([string]::IsNullOrEmpty($SQLServerName) -or [string]::IsNullOrEmpty($DBName)) {
"server Name or database name is not valid."
"Exiting....."
exit
}

#Set CSV file path
IF([string]::IsNullOrEmpty($CSVFilePath)) {
$CSVFilePath=$ScriptDir
}
#Check if CSV file path is valid and exit if it is not 
IF(!(Test-Path $CSVFilePath) ) {
"CSV file Path is not valid."
"Exiting....."
exit
}

############ Import User Defined modules ##############
import-module $ScriptDir\Export-SQLTable2CSV -Force

############# MAIN ####################
#Loop through each table in the XML file
FOREACH( $Tables in $XmlSubsetTableList.DB.Table) {
    $TableName=$Tables.TableName
    $ClientKeyColumnName=$Tables.ClientKeyColumnName
    $DateRangeColumnName=$Tables.DateRangeColumnName
    $SelectQuery=$Tables.SelectQuery

    if ([string]::IsNullOrEmpty($TableName)){
       continue;
    }
    #set Csv file name
    $CSVFileName=$TableName+".csv"

    #set Select Query
    if([string]::IsNullOrEmpty($SelectQuery)){
    $SelectQuery="select * from $TableName (nolock)"
    }

    #####Add filters to select query######
    # apply clientkey filter if passed from the command line and the  ClientKeyColumnName exists in the xml file for this table
    if (!([string]::IsNullOrEmpty($ClientKey)) -and !([string]::IsNullOrEmpty($ClientKeyColumnName))){
        $SelectQuery="$SelectQuery where "
        $SelectQuery="$SelectQuery $ClientKeyColumnName=$ClientKey"
        }

    # apply Daterange filter if passed from the command line and the  DateRangeColumnName exists in the xml file for this table
    if (!([string]::IsNullOrEmpty($DateRangeColumnName)) -and !([string]::IsNullOrEmpty($FromDate))  -and !([string]::IsNullOrEmpty($ToDate))){
         if ($SelectQuery.ToLower().Contains("where".ToLower())){
                $SelectQuery="$SelectQuery and"                
            }
            else{
             $SelectQuery="$SelectQuery where" 
            }
            $SelectQuery="$SelectQuery $DateRangeColumnName between '$FromDate' and '$ToDate'"
        }
    
    Try{
        #export records to CSV
        write-host "START Exporting table $TableName to CSV file $CSVFilePath\$CSVFileName at "(Get-Date)
         Export-SQLTable2CSV -SQLServerName $SQLServerName -DBName $DBName -SelectQuery $SelectQuery -CSVFilePath $CSVFilePath -CSVFileName $CSVFileName -CSVDelimiter $CSVDelimiter
         write-host "END Exporting table $TableName to CSV file at "(Get-Date)
    }
    Catch{
      $output = "Failure:`n`n " + $_.Exception        
       write-host  $output  
       write-host "FAILED to Export table '$TableName' to CSV file, at "(Get-Date)".See above message for details"-foregroundcolor "RED"
       write-host "Continuing with other tables...." -foregroundcolor "RED"
    }
  }
#END for each Loop
}
###########End TRY####################
############Start Catch#############
CATCH [Exception]
    {     
        $output = "Failure:`n`n " + $_.Exception        
        throw $output  
        
    }
###########Start finally#############
FINALLY{
   
}
