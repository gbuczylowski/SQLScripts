# SQLScripts


sp_SearchSqlLogs - Scans SQL Database Engine and SQL Agent error logs for specific search terms or retrieves entire or selected number of error logs.

Parameters:
@SearchTerm - Keyword to search. If skipped all (or selected in @NumberOfLogs) log records are retrieved.
@LogType - 1 for SQL Database Engine, 2 for SQL Agent.
@NumberOfLogs - Number of logs to retrieve. If skipped or too many logs requested, it defaults to actual number of available logs.