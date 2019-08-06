# Readme

> This is the repo contains the source code for `aletasystems/tsqlrunner` docker container. 

## About this Image

> Objective: A basic image that can help with running t-sql scripts to be used in conjunction with Docker-Compose files. 

This image based on `mcr.microsoft.com/mssql-tools:latest` and is used to execute T-SQL scripts located in `/tsqlscripts` VOLUME. 

1. The shell script `execute-sql-scripts` will run all scripts in `/tsqlscripts/master` (alphabetically)
2. Each sub-folder within `/tsqlscripts` is considered as the database name
3. Any script within a sub-folder is executed against that database named as the sub-folder (it will create the database)


## Examples

### SQL Server Deployment - FlyWay

Sample Compose file that creates a SQL Server container, executes tsql_files against it and then deploys code using Flyway. 

```yml
version: '3'
services:
    db:
        image: mcr.microsoft.com/mssql/server
        volumes: 
          - ./Datasets:/Datasets
        environment:
            SA_PASSWORD: ${SQL_SERVER_PASSWORD}
            ACCEPT_EULA: Y
        ports:
            - '14333:1433'

    inittools:
        image: aletasystems/tsqlrunner
        volumes: 
          - ./tsql_files:/tsqlscripts
        environment:
            SQLCMDSERVER: db
            SQLCMDUSER: sa
            SQLCMDPASSWORD: ${SQL_SERVER_PASSWORD}
        command: '/tooling/execute-sql-scripts.sh'

    flyway:
        image: 'boxfuse/flyway:5.2.4'
        command: '-user=sa -password=${SQL_SERVER_PASSWORD} -url="jdbc:sqlserver://db;databaseName=DataWarehouse" -connectRetries=60 migrate'
        volumes:
            - './db_Datawarehouse/sql:/flyway/sql'
            - './db_Datawarehouse/conf:/flyway/conf'
        depends_on:
            - inittools
            - db
```
