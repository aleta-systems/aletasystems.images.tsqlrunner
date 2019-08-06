# Build an image of mssql-tools
FROM mcr.microsoft.com/mssql-tools
 
# Create /tooling
RUN mkdir /tooling
COPY ./tooling/execute-sql-scripts.sh /tooling

RUN ["chmod", "+x", "/tooling/execute-sql-scripts.sh"]

RUN mkdir /tsqlscripts
VOLUME /tsqlscripts

ENTRYPOINT /tooling/execute-sql-scripts.sh
