
USE master;
GO

IF OBJECT_ID('dbo.sp_SearchSqlLogs') IS NULL
BEGIN
	EXEC ('CREATE PROCEDURE dbo.sp_SearchSqlLogs WITH RECOMPILE AS RETURN 0;');
END;
GO

ALTER PROCEDURE dbo.sp_SearchSqlLogs 
				  @SearchTerm nvarchar(512)= NULL
				, @LogType int= 1 -- SQL Engine Logs by default
				, @NumberOfLogs int= NULL
WITH RECOMPILE
AS
BEGIN
/**********************************************************************************************************

    NAME:           sp_SearchSqlLogs

    SYNOPSIS:       Search SQL Engine & Agent error logs

    AUTHOR:         Grzegorz Buczylowski https://gbuit.co.uk/
    
    CREATED:        2019-03-14
    
    VERSION:        1.0

    LICENSE:        MIT

    ----------------------------------------------------------------------------
    DISCLAIMER: 
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
	SOFTWARE.
    ----------------------------------------------------------------------------

 ---------------------------------------------------------------------------------------------------------
 --  DATE       VERSION     AUTHOR                  DESCRIPTION                                        --
 ---------------------------------------------------------------------------------------------------------
     20190314   1.0         Grzegorz Buczylowski    Open Sourced on GitHub
**********************************************************************************************************/

	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	SET ANSI_PADDING ON;
	SET ANSI_WARNINGS ON;
	SET ARITHABORT ON;
	SET CONCAT_NULL_YIELDS_NULL ON;
	SET NUMERIC_ROUNDABORT OFF;


	BEGIN

		DECLARE @i int= 0; -- Start at the first log file
		DECLARE @SQL varchar(1024);

		-- Check log type
		IF @LogType NOT IN(1, 2)
		BEGIN
			PRINT 'Incorrect log type. Only values of 1 - SQL Engine Error Log, and 2 - SQL Agent Error Log are allowed.';
			RETURN;
		END;

		-- Check how many logs are available
		DECLARE @LogList TABLE
		( 
							   LogNumber int, StartDate char(17), SizeInBytes int
		);
		INSERT INTO @LogList
		EXEC xp_enumerrorlogs @LogType;

		IF @NumberOfLogs >
		(
			SELECT MAX(LogNumber)
			FROM @LogList
		)
		BEGIN
			SELECT @NumberOfLogs = MAX(LogNumber)
			FROM @LogList;
			PRINT 'More logs requested than exist on this instance. Only ' + CAST(@NumberOfLogs AS varchar(9)) + ' logs available.';
		END;

		IF @NumberOfLogs IS NULL
		BEGIN
			SELECT @NumberOfLogs = MAX(LogNumber)
			FROM @LogList;
			PRINT 'Number of logs to scan was not specified. Using all available logs (' + CAST(@NumberOfLogs AS varchar(9)) + ').';
		END;

		--PRINT 'NumberOfLogs: ' + CAST(@NumberOfLogs AS varchar(9));

		-- Retrieve logs when no search term is specified
		IF @SearchTerm IS NULL
		BEGIN
			--PRINT 'no'
			IF OBJECT_ID('tempdb..#ErrorLogs1') IS NOT NULL
			BEGIN
				DROP TABLE #ErrorLogs1;
			END;
			CREATE TABLE #ErrorLogs1
			( 
						 LogDate datetime, ProcessInfo varchar(50), [Text] varchar(4000)
			);

			WHILE @i <= @NumberOfLogs
			BEGIN
				SET @SQL = 'INSERT INTO #ErrorLogs1 EXEC xp_readerrorlog ' + CAST(@i AS varchar(3)) + ', ' + CAST(@LogType AS char(1));
				--SELECT (@SQL)
				EXEC (@SQL);
				SET @i = @i + 1;
			END;

			SELECT *
			FROM #ErrorLogs1
			ORDER BY LogDate DESC;

		END;

		-- Retrieve logs when search term is specified
		IF @SearchTerm IS NOT NULL
		BEGIN
			--PRINT 'yes'
			IF OBJECT_ID('tempdb..#ErrorLogs2') IS NOT NULL
			BEGIN
				DROP TABLE #ErrorLogs2;
			END;
			CREATE TABLE #ErrorLogs2
			( 
						 LogDate datetime, ProcessInfo varchar(50), [Text] varchar(4000)
			);

			WHILE @i <= @NumberOfLogs
			BEGIN
				SET @SQL = 'INSERT INTO #ErrorLogs2 EXEC xp_readerrorlog ' + CAST(@i AS varchar(3)) + ', ' + CAST(@LogType AS char(1)) + ', "' + @SearchTerm + '"';
				--SELECT (@SQL)
				EXEC (@SQL);
				SET @i = @i + 1;
			END;

			SELECT *
			FROM #ErrorLogs2
			ORDER BY LogDate DESC;

		END;

	END;
END;