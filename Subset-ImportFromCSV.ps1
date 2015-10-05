########################################################################################### 
# Name         : Subset-Import2SQLTable
# Author       : Pramod Singla (Ecova DBAs) 17th Sept 2015
# Purpose      : It imports CSV files data into SQL table. It will get the list of tables from the XML file and load all these tables with corresponding CSV file.
#              : The name of the table and CSV file should be same.
# Test String  : .\Subset-Import2SQLTable.ps1  -ClientKey 2 
#              : .\Subset-Import2SQLTable.ps1  -ClientKey 2  -CSVFilePath E:\My_Work\Subset_EDGEDW\CSVFileFolder 
# Requires     : Script is developed and tested on PS vesion 4, a XML file(SubsetTableList.xml) of following format
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
(   [string]$SQLServerName ="localhost",
	[string]$DBName ,
    [string]$CSVFilePath=$null     
)
#### Start TRY (Entry Point) #################
TRY
{

################## Setting Variables ###################
$CSVDelimiter = "~" 

#Get current execution\script path
$ScriptDir = Split-Path -parent $MyInvocation.MyCommand.Path


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

#Read the table list to subset
[xml]$XmlSubsetTableList = Get-Content -Path "$ScriptDir\SubsetTableList.xml"

############ Import User Defined modules ##############
import-module $ScriptDir\Import-CSV2SQLTable -Force
#  write-host "couldn't create csv for Table:$TableName becuase it's name is not valid in XML file.Continuing with other tables...." -foregroundcolor "RED"
#exit
############# MAIN ####################
#Loop through each table in the XML file
FOREACH( $Tables in $XmlSubsetTableList.DB.Table) {
    $TableName=$Tables.TableName


    if ([string]::IsNullOrEmpty($TableName)){
        continue;
    }
    #set Csv file name
    $CSVFileName=$TableName+".csv"


    Try{
        #Import CSV records into SQL Table
        write-host "START Importing table $TableName from CSV file $CSVFilePath\$CSVFileName at "(Get-Date)
       # Export-SQLTable2CSV -SQLServerName $SQLServerName -DBName $DBName -SelectQuery $SelectQuery -CSVFilePath $CSVFilePath -CSVFileName $CSVFileName -CSVDelimiter $CSVDelimiter
        Import-CSV2SQLTable -SQLServerName $SQLServerName -DBName $DBName -TableName $TableName -CSVFilePath $CSVFilePath -CSVFileName $CSVFileName -CSVDelimiter $CSVDelimiter
        write-host "END Importing table $TableName from CSV file at "(Get-Date)

    }
    Catch{
        $output = "Failure:`n`n " + $_.Exception        
        write-host  $output  
       write-host "FAILED to import table '$TableName' from CSV file, at "(Get-Date)".See above message for details"-foregroundcolor "RED"
       write-host "Continuing with other tables...." -foregroundcolor "RED"
        Continue;
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

