#!/bin/bash
retry=0;
path_2_sql_files='/tsqlscripts'

# Test Connectivity 5 retries
testQuery=$(/opt/mssql-tools/bin/sqlcmd -S "$SQLCMDSERVER" -d master -U "$SQLCMDUSER" -P "$SQLCMDPASSWORD" -Q 'SET NOCOUNT ON; SELECT 1' -W -h -1)
while [ "$testQuery" != '1' ] || [ $retry -gt 5 ] ; do
    testQuery=$(/opt/mssql-tools/bin/sqlcmd -S "$SQLCMDSERVER" -d master -U "$SQLCMDUSER" -P "$SQLCMDPASSWORD" -Q 'SET NOCOUNT ON; SELECT 1' -W -h -1)
    retry=$(retry+1)
done

# Execute Master Scripts
printf "[PROCESS | Sql Files for (Master) DataBase]\n"
for tsqlFile in $(find $path_2_sql_files -wholename "$path_2_sql_files/master/*.sql"); do
    
    printf "\t|/opt/mssql-tools/bin/sqlcmd -S $SQLCMDSERVER -d master -U $SQLCMDUSER -i \"$tsqlFile\" ;\n"
    /opt/mssql-tools/bin/sqlcmd -S "$SQLCMDSERVER" -d master -U "$SQLCMDUSER" -P "$SQLCMDPASSWORD" -i "$tsqlFile";

done

# Execute User Database Files | 1:1 | Database:Folder
for database_name in $(find $path_2_sql_files ! -path "$path_2_sql_files" -type d -printf "%f\n"); do

    printf "[PROCESS | Sql Files for ($database_name) DataBase]\n"
    
    shopt -s nocasematch
    if([[ $database_name != "master" ]]) then
        
        # Create Database IF NOT EXISTS
        queryStatement="IF DB_ID('[$database_name]') IS NOT NULL CREATE DATABASE [$database_name];\n"
        q=$(printf "$queryStatement")
        printf "\t| TRY CREATE DATABASE $database_name\n"
        printf "\t\t|/opt/mssql-tools/bin/sqlcmd -S $SQLCMDSERVER -d master -U $SQLCMDUSER -q \"$q\" ;\n"
        
        /opt/mssql-tools/bin/sqlcmd -S "$SQLCMDSERVER" -d master -U "$SQLCMDUSER" -P "$SQLCMDPASSWORD" -q "$q";


        # Execute Database Specific Files
        printf "\t| Execute SqlFile $database_name\n"
        for tsqlFile in $(find $path_2_sql_files/"$database_name"/*.sql); do

            printf "\t\t|/opt/mssql-tools/bin/sqlcmd -S $SQLCMDSERVER -d $database_name -U $SQLCMDUSER -i \"$tsqlFile\" ;\n"
            /opt/mssql-tools/bin/sqlcmd -S "$SQLCMDSERVER" -d "$database_name" -U "$SQLCMDUSER" -P "$SQLCMDPASSWORD" -i "$tsqlFile";
        
        done
    fi
    shopt -u nocasematch
done