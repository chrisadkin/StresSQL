﻿/*
Deployment script for StressTest

This code was generated by a tool.
Changes to this file may cause incorrect behavior and will be lost if
the code is regenerated.
*/

GO
SET ANSI_NULLS, ANSI_PADDING, ANSI_WARNINGS, ARITHABORT, CONCAT_NULL_YIELDS_NULL, QUOTED_IDENTIFIER ON;

SET NUMERIC_ROUNDABORT OFF;


GO
:setvar DatabaseName "StressTest"
:setvar DefaultFilePrefix "StressTest"
:setvar DefaultDataPath "C:\Program Files\Microsoft SQL Server\MSSQL13.SQL2016\MSSQL\DATA\"
:setvar DefaultLogPath "C:\Program Files\Microsoft SQL Server\MSSQL13.SQL2016\MSSQL\DATA\"

GO
:on error exit
GO
/*
Detect SQLCMD mode and disable script execution if SQLCMD mode is not supported.
To re-enable the script after enabling SQLCMD mode, execute the following:
SET NOEXEC OFF; 
*/
:setvar __IsSqlCmdEnabled "True"
GO
IF N'$(__IsSqlCmdEnabled)' NOT LIKE N'True'
    BEGIN
        PRINT N'SQLCMD mode must be enabled to successfully execute this script.';
        SET NOEXEC ON;
    END


GO
USE [$(DatabaseName)];


GO
PRINT N'Dropping [dbo].[usp_PushMessageImOltpNoSequence]...';


GO
DROP PROCEDURE [dbo].[usp_PushMessageImOltpNoSequence];


GO
PRINT N'Altering [dbo].[usp_LmaxPushDiskNoSequence]...';


GO

ALTER PROCEDURE [dbo].[usp_LmaxPushDiskNoSequence] @TransactionsPerThread int = 200000
AS 
BEGIN 
    DECLARE  @MessagePopped int
            ,@i             int = 0;

    SET NOCOUNT ON;

	WHILE @i <= @TransactionsPerThread 
	BEGIN
		EXEC dbo.usp_PushMessageDiskNoSequence @MessagePopped OUTPUT; 
		SET @i += 1;
	END;
END;
GO
PRINT N'Altering [dbo].[usp_LmaxPushDiskNumaNoSequence]...';


GO

ALTER PROCEDURE [dbo].[usp_LmaxPushDiskNumaNoSequence] @TransactionsPerThread int = 200000
AS 
BEGIN 
    DECLARE  @MessagePushed int
            ,@Slot          int
            ,@i             int = 0;

    SET NOCOUNT ON;

	IF EXISTS (SELECT 1
               FROM   sys.dm_exec_requests r
               JOIN   sys.dm_os_workers    w
               ON     r.task_address = w.task_address
               JOIN   sys.dm_os_schedulers s
               ON     s.scheduler_address = w.scheduler_address
               WHERE  r.session_id     = @@SPID
			   AND    s.parent_node_id = 0)
	BEGIN
		WHILE @i <= @TransactionsPerThread 
		BEGIN
			EXEC dbo.usp_PushMessageDiskNoSequenceNode0 @MessagePushed OUTPUT; 
			SET @i += 1;
		END;
	END
	ELSE
	BEGIN
		WHILE @i <= @TransactionsPerThread
		BEGIN
			EXEC dbo.usp_PushMessageDiskNoSequenceNode1 @MessagePushed OUTPUT; 
			SET @i += 1;
		END;
	END
END;
GO
PRINT N'Altering [dbo].[usp_LmaxPushDiskNumaSequence]...';


GO

ALTER PROCEDURE [dbo].[usp_LmaxPushDiskNumaSequence] @TransactionsPerThread int = 200000
AS 
BEGIN 
    DECLARE  @MessagePushed int
            ,@Slot          int
            ,@i             int = 0;

    SET NOCOUNT ON;

	IF EXISTS (SELECT 1
               FROM   sys.dm_exec_requests r
               JOIN   sys.dm_os_workers    w
               ON     r.task_address = w.task_address
               JOIN   sys.dm_os_schedulers s
               ON     s.scheduler_address = w.scheduler_address
               WHERE  r.session_id     = @@SPID
			   AND    s.parent_node_id = 0)
	BEGIN
		WHILE @i <= @TransactionsPerThread 
		BEGIN
			EXEC dbo.usp_PushMessageDiskSequenceNode0 @MessagePushed OUTPUT; 
			SET @i += 1;
		END;
	END
	ELSE
	BEGIN
		WHILE @i <= @TransactionsPerThread 
		BEGIN
			EXEC dbo.usp_PushMessageDiskSequenceNode1 @MessagePushed OUTPUT; 
			SET @i += 1;
		END;
	END
END;
GO
PRINT N'Altering [dbo].[usp_LmaxPushDiskSequence]...';


GO

ALTER PROCEDURE [dbo].[usp_LmaxPushDiskSequence] @TransactionsPerThread int = 200000
AS 
BEGIN 
    DECLARE  @MessagePushed int
            ,@Slot          int
            ,@i             int = 0;

    SET NOCOUNT ON;

	WHILE @i <= @TransactionsPerThread 
	BEGIN
		EXEC dbo.usp_PushMessageDiskSequence @MessagePushed OUTPUT; 
		SET @i += 1;
	END;
END;
GO
PRINT N'Altering [dbo].[usp_LmaxPushImOltpSequence]...';


GO
ALTER PROCEDURE [dbo].[usp_LmaxPushImOltpSequence] @TransactionsPerThread int = 200000
AS 
BEGIN 
    DECLARE  @QueueSize     INT = 4000000
	        ,@MessagePushed INT
            ,@Slot          INT
	        ,@i             INT = 0;

    WHILE @i <= @TransactionsPerThread 
    BEGIN
	    SET @MessagePushed = 0;

		WHILE @MessagePushed = 0
		BEGIN
	        SELECT @Slot = NEXT VALUE FOR [dbo].[PushSequence] % @QueueSize
            EXEC dbo.usp_PushMessageImOltpSequence @Slot, @MessagePushed OUTPUT;
		END;

		SET @i += 1;
    END;
END;
GO
PRINT N'Creating [dbo].[usp_PushMessageImOltpNoSequence]...';


GO
CREATE PROCEDURE [dbo].[usp_PushMessageImOltpNoSequence]  
WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC
    WITH ( TRANSACTION ISOLATION LEVEL = SNAPSHOT
          ,LANGUAGE                    = N'us_english')

    DECLARE  @MessagePushed int
	        ,@QueueSize     int = 200000
			,@Slot          bigint;

	SET @MessagePushed = 0;

	WHILE @MessagePushed = 0
	BEGIN
		INSERT INTO [dbo].[NonBlockingSequence]
			DEFAULT VALUES;

		SELECT @Slot = SCOPE_IDENTITY();
	
		DELETE FROM [dbo].[NonBlockingSequence] WHERE ID = @Slot;
		
		UPDATE [dbo].[MyQLmaxImOltp]
		SET     time            = GETDATE()
			   ,message         = 'Hello world'
			   ,message_id      = @Slot
			   ,reference_count = reference_count + 1
		WHERE   Slot            = @Slot % @QueueSize
		AND     reference_count = 0;

		SET @MessagePushed = @@ROWCOUNT;
	END;
END;
GO
PRINT N'Altering [dbo].[usp_StresSQL]...';


GO
ALTER PROCEDURE [dbo].[usp_StresSQL] 
     @Test                  VARCHAR(256)
	,@StartThread           INT            = 1
	,@EndThread             INT            = 20
    ,@Procedure1            VARCHAR(256)   = 'LmaxPushV3Wrapper'
    ,@Procedure2            VARCHAR(256)   = 'NO POP PROCEDURE'
	,@InitProcedure         NVARCHAR(256)  = N'NO INIT PROCEDURE'
	,@TransactionsPerThread BIGINT         = 200000
	,@CommitBatchSize       INT            = 1
AS
BEGIN
    DECLARE  @DatabaseName VARCHAR(256)   = ''
            ,@AlterDbCmd   NVARCHAR(128)            
			,@StartTime    DATETIME
	        ,@Server       VARCHAR(256)       
            ,@InitCmd      NVARCHAR(512)
            ,@PshCmd       VARCHAR(512)
			,@i            BIGINT;

    DECLARE @WaitStats TABLE (
	     [Rank]       [bigint]         NULL
		,[WaitType]   [nvarchar](60)   NULL
		,[Wait_S]     [decimal](16, 2) NULL
		,[WaitCount]  [bigint]         NULL
		,[Percentage] [decimal](5, 2)  NULL
		,[AvgWait_S]  [decimal](16, 4) NULL
	);

	DECLARE @SpinlockStats TABLE (
         [Rank]                [tinyint]      NULL
		,[name]                [varchar](256) NULL
		,[collisions]          [bigint]       NULL
		,[spins]               [bigint]       NULL
		,[spins_per_collision] [real]         NULL
		,[sleep_time]          [bigint]       NULL
		,[backoffs]            [bigint]       NULL
	);

	SET NOCOUNT ON;

	SET @i = @StartThread;

	SELECT @DatabaseName = DB_NAME();
	SELECT @Server       = @@SERVERNAME;

	WHILE @i <= @EndThread
	BEGIN	
	    IF NOT EXISTS (SELECT 1
		               FROM   StresSQLStats
					   WHERE  Test    = @Test
					   AND    Threads = @i)
		BEGIN
			IF @InitProcedure <> 'NO INIT PROCEDURE'
			BEGIN
				SET @InitCmd = 'EXECUTE ' + @InitProcedure;
				EXECUTE sp_executesql @InitCmd;
			END;

			SET @AlterDbCmd = 'ALTER DATABASE ' + @DatabaseName + ' SET RECOVERY SIMPLE';
			EXECUTE sp_executesql @AlterDbCmd;
			SET @AlterDbCmd = 'ALTER DATABASE ' + @DatabaseName + ' SET RECOVERY FULL';
			EXECUTE sp_executesql @AlterDbCmd;

			INSERT INTO [dbo].[StresSQLStats] ( Test
												 ,Threads
												 ,StartTime )
			VALUES ( @Test
					,@i
					,GETDATE());
			IF @CommitBatchSize > 1
			BEGIN
				SET @PshCmd = 'PowerShell.exe -noprofile -command ' + '"' +
								'for($i=1; $i -le ' + CAST(@i AS char(2)) + '; $i++) { ' +
									'Start-Job { Invoke-sqlcmd -Database ' + @DatabaseName +
									' -ServerInstance ' + @Server + 
									' -Query \"EXECUTE ' + @Procedure1 + ' @TransactionsPerThread = ' + CAST(@TransactionsPerThread AS VARCHAR) +
									', @CommitBatchSize = ' + CAST(@CommitBatchSize AS VARCHAR) + '\" }';
			END
			ELSE
			BEGIN
				SET @PshCmd = 'PowerShell.exe -noprofile -command ' + '"' +
								'for($i=1; $i -le ' + CAST(@i AS char(2)) + '; $i++) { ' +
									'Start-Job { Invoke-sqlcmd -Database ' + @DatabaseName +
									' -ServerInstance ' + @Server + 
									' -Query \"EXECUTE ' + @Procedure1 + ' @TransactionsPerThread = ' + CAST(@TransactionsPerThread AS VARCHAR) + '\" }';
			END;
		
			IF @Procedure2 <> 'NO POP PROCEDURE'
			BEGIN
				IF @CommitBatchSize > 1
				BEGIN
					SET @PshCmd += ';Start-Job { Invoke-sqlcmd -Database ' + @DatabaseName +
										' -ServerInstance ' + @Server + 
										' -Query \"EXECUTE ' + @Procedure2 + ' @TransactionsPerThread = ' + CAST(@TransactionsPerThread AS VARCHAR) +
										', @CommitBatchSize = ' + CAST(@CommitBatchSize AS VARCHAR) + '\" }';
				END
				ELSE
				BEGIN
					SET @PshCmd += ';Start-Job { Invoke-sqlcmd -Database ' + @DatabaseName +
										' -ServerInstance ' + @Server + 
										' -Query \"EXECUTE ' + @Procedure2 + ' @TransactionsPerThread = ' + CAST(@TransactionsPerThread AS VARCHAR) + '\" }';
				END;
			END;

			SET @PshCmd += '}; while (Get-Job -state running) { Start-Sleep -Seconds 1 }"';

			SELECT @PshCmd AS [@PshCmd];

			DBCC SQLPERF("sys.dm_os_spinlock_stats", clear)
			DBCC SQLPERF("sys.dm_os_latch_stats"   , clear)
			DBCC SQLPERF("sys.dm_os_wait_stats"    , clear)

			SET @StartTime = GETDATE();	

			EXECUTE xp_cmdshell @PshCmd;

			IF DATEDIFF(ms, @StartTime, GETDATE()) > 0
			BEGIN
				UPDATE  [dbo].[StresSQLStats]
				SET     [TransactionRate] = ((@i * @TransactionsPerThread) * CAST(1000 AS bigint)
											 / CAST(DATEDIFF(ms, @StartTime, GETDATE()) AS bigint))
					   ,[EndTime]         = GETDATE()
				WHERE  Threads = @i
				AND    Test    = @Test;

				DELETE FROM @WaitStats;

				WITH [Waits] AS (SELECT  [wait_type]
										,[wait_time_ms] / 1000.0                              AS [WaitS]
										,([wait_time_ms] - [signal_wait_time_ms]) / 1000.0    AS [ResourceS]
										,[signal_wait_time_ms] / 1000.0                       AS [SignalS]
										,[waiting_tasks_count]                                AS [WaitCount]
										,100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage]
										,ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC)      AS [RowNum]
								 FROM    sys.dm_os_wait_stats
								 WHERE   [wait_type] NOT IN ( N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR',
															  N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH',
															  N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
															  N'CHKPT', N'CLR_AUTO_EVENT',
															  N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
															  -- Maybe uncomment these four if you have mirroring issues
															  N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE',
															  N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD',
															  N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
															  N'EXECSYNC', N'FSAGENT',
															  N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
															  -- Maybe uncomment these six if you have AG issues
															  N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
															  N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE',
															  N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
															  N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP',
															  N'LOGMGR_QUEUE', N'MEMORY_ALLOCATION_EXT',
															  N'ONDEMAND_TASK_QUEUE',
															  N'PREEMPTIVE_XE_GETTARGETSTATE',
															  N'PWAIT_ALL_COMPONENTS_INITIALIZED',
															  N'PWAIT_DIRECTLOGCONSUMER_GETNEXT',
															  N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', N'QDS_ASYNC_QUEUE',
															  N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
															  N'QDS_SHUTDOWN_QUEUE', N'REDO_THREAD_PENDING_WORK',
															  N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
															  N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH',
															  N'SLEEP_DBSTARTUP', N'SLEEP_DCOMSTARTUP',
															  N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
															  N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP',
															  N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
															  N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT',
															  N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
															  N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
															  N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS',
															  N'WAITFOR', N'WAITFOR_TASKSHUTDOWN',
															  N'WAIT_XTP_RECOVERY',
															  N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
															  N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
															  N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT',
															  N'PREEMPTIVE_XE_DISPATCHER', N'CXPACKET',
															  N'PREEMPTIVE_OS_PIPEOPS', N'PREEMPTIVE_XE_CALLBACKEXECUTE')
								 AND     [waiting_tasks_count] > 0
								)
				INSERT INTO @WaitStats (
						  [Rank]       
						 ,[WaitType]   
						 ,[Wait_S]     
						 ,[WaitCount]  
						 ,[Percentage] 
						 ,[AvgWait_S]  
				)
				SELECT TOP 5 W1.RowNum                                                        AS [Rank]
					  ,MAX ([W1].[wait_type])                                                 AS [WaitType]
					  ,CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2))                            AS [Wait_S]
					  ,MAX ([W1].[WaitCount])                                                 AS [WaitCount]
					  ,CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2))                        AS [Percentage]
					  ,CAST ((MAX ([W1].[WaitS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgWait_S]
				FROM   [Waits] AS [W1]
				JOIN   [Waits] AS [W2]
				ON     [W2].[RowNum] <= [W1].[RowNum]
				GROUP  BY [W1].[RowNum]
				HAVING SUM ([W2].[Percentage]) - MAX( [W1].[Percentage] ) < 95 -- percentage threshold
				ORDER  BY CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) DESC;

				UPDATE      ists
				SET         ists.[WaitType_1]   = wsts.[WaitType]
						   ,ists.[Wait_S_1]     = wsts.[Wait_S]
						   ,ists.[WaitCount_1]  = wsts.[WaitCount]
						   ,ists.[Percentage_1] = wsts.[Percentage]
						   ,ists.[AvgWait_S_1]  = wsts.[AvgWait_S]
				FROM        StresSQLStats AS ists
				CROSS JOIN  @WaitStats      AS wsts
				WHERE       ists.Threads = @i
				AND         ists.Test    = @Test
				AND         wsts.[Rank]  = 1;

				UPDATE      ists
				SET         ists.[WaitType_2]   = wsts.[WaitType]
						   ,ists.[Wait_S_2]     = wsts.[Wait_S]
						   ,ists.[WaitCount_2]  = wsts.[WaitCount]
						   ,ists.[Percentage_2] = wsts.[Percentage]
						   ,ists.[AvgWait_S_2]  = wsts.[AvgWait_S]
				FROM        StresSQLStats AS ists
				CROSS JOIN  @WaitStats      AS wsts
				WHERE       ists.Threads = @i
				AND         ists.Test    = @Test
				AND         wsts.[Rank]  = 2;

 				UPDATE      ists
				SET         ists.[WaitType_3]   = wsts.[WaitType]
						   ,ists.[Wait_S_3]     = wsts.[Wait_S]
						   ,ists.[WaitCount_3]  = wsts.[WaitCount]
						   ,ists.[Percentage_3] = wsts.[Percentage]
						   ,ists.[AvgWait_S_3]  = wsts.[AvgWait_S]
				FROM        StresSQLStats AS ists
				CROSS JOIN  @WaitStats      AS wsts
				WHERE       ists.Threads = @i
				AND         ists.Test    = @Test
				AND         wsts.[Rank]  = 3;

 				UPDATE      ists
				SET         ists.[WaitType_4]   = wsts.[WaitType]
						   ,ists.[Wait_S_4]     = wsts.[Wait_S]
						   ,ists.[WaitCount_4]  = wsts.[WaitCount]
						   ,ists.[Percentage_4] = wsts.[Percentage]
						   ,ists.[AvgWait_S_4]  = wsts.[AvgWait_S]
				FROM        StresSQLStats AS ists
				CROSS JOIN  @WaitStats      AS wsts
				WHERE       ists.Threads = @i
				AND         ists.Test    = @Test
				AND         wsts.[Rank]  = 4;

 				UPDATE      ists
				SET         ists.[WaitType_5]   = wsts.[WaitType]
						   ,ists.[Wait_S_5]     = wsts.[Wait_S]
						   ,ists.[WaitCount_5]  = wsts.[WaitCount]
						   ,ists.[Percentage_5] = wsts.[Percentage]
						   ,ists.[AvgWait_S_5]  = wsts.[AvgWait_S]
				FROM        StresSQLStats AS ists
				CROSS JOIN  @WaitStats  AS wsts
				WHERE       ists.Threads = @i
				AND         ists.Test    = @Test
				AND         wsts.[Rank]  = 5;

				WITH Latch_CTE AS (
					SELECT    TOP 5 ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [Rank]
							  ,latch_class
							  ,wait_time_ms 
					FROM      sys.dm_os_latch_stats
					WHERE     latch_class <> 'BUFFER'
					ORDER BY  wait_time_ms DESC)
				UPDATE      ists
				SET         ists.[latch_class_1]   = lsts.[latch_class]
						   ,ists.[wait_time_ms_1]  = lsts.[wait_time_ms]
				FROM        StresSQLStats AS ists
				CROSS JOIN  Latch_CTE   AS lsts
				WHERE       ists.Threads = @i
				AND         ists.Test    = @Test
				AND         lsts.[Rank]  = 1;

				WITH Latch_CTE AS (
					SELECT    TOP 5 ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [Rank]
							 ,latch_class
							 ,wait_time_ms 
					FROM      sys.dm_os_latch_stats
					WHERE     latch_class <> 'BUFFER'
					ORDER BY  wait_time_ms DESC)
				UPDATE      ists
				SET         ists.[latch_class_2]   = lsts.[latch_class]
						   ,ists.[wait_time_ms_2]  = lsts.[wait_time_ms]
				FROM        StresSQLStats AS ists
				CROSS JOIN  Latch_CTE   AS lsts
				WHERE       ists.Threads = @i
				AND         ists.Test    = @Test
				AND         lsts.[Rank]  = 2;

				WITH Latch_CTE AS (
					SELECT    TOP 5 ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [Rank]
							 ,latch_class
							 ,wait_time_ms 
					FROM      sys.dm_os_latch_stats
					WHERE     latch_class <> 'BUFFER'
					ORDER BY  wait_time_ms DESC)
				UPDATE      ists
				SET         ists.[latch_class_3]   = lsts.[latch_class]
						   ,ists.[wait_time_ms_3]  = lsts.[wait_time_ms]
				FROM        StresSQLStats AS ists
				CROSS JOIN  Latch_CTE   AS lsts
				WHERE       ists.Threads = @i
				AND         ists.Test    = @Test
				AND         lsts.[Rank]  = 3;

				WITH Latch_CTE AS (
					SELECT    TOP 5 ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [Rank]
							 ,latch_class
							 ,wait_time_ms 
					FROM      sys.dm_os_latch_stats
					WHERE     latch_class <> 'BUFFER'
					ORDER BY  wait_time_ms DESC)
				UPDATE      ists
				SET         ists.[latch_class_4]   = lsts.[latch_class]
						   ,ists.[wait_time_ms_4]  = lsts.[wait_time_ms]
				FROM        StresSQLStats AS ists
				CROSS JOIN  Latch_CTE   AS lsts
				WHERE       ists.Threads = @i
				AND         ists.Test    = @Test
				AND         lsts.[Rank]  = 4;

				WITH Latch_CTE AS (
					SELECT    TOP 5 ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [Rank]
							 ,latch_class
							 ,wait_time_ms 
					FROM      sys.dm_os_latch_stats
					WHERE     latch_class <> 'BUFFER'
					ORDER BY  wait_time_ms DESC)
				UPDATE      ists
				SET         ists.[latch_class_5]   = lsts.[latch_class]
						   ,ists.[wait_time_ms_5]  = lsts.[wait_time_ms]
				FROM        StresSQLStats AS ists
				CROSS JOIN  Latch_CTE   AS lsts
				WHERE       ists.Threads = @i
				AND         ists.Test    = @Test
				AND         lsts.[Rank]  = 5;

				DELETE FROM @SpinlockStats;

				INSERT INTO @SpinlockStats (
						  [Rank]                
						 ,[name]                
						 ,[collisions]          
						 ,[spins]               
						 ,[spins_per_collision] 
						 ,[sleep_time]          
						 ,[backoffs]            
				)
				SELECT    TOP 5 ROW_NUMBER() OVER(ORDER BY [spins] DESC) AS [Rank]
						 ,name
						 ,collisions
						 ,spins
						 ,spins_per_collision
						 ,sleep_time
						 ,backoffs
				FROM     sys.dm_os_spinlock_stats
				ORDER BY spins DESC;
		
				UPDATE      ists
				SET          [spinlock_name_1]       = ssts.name
							,[spins_1]               = ssts.spins
							,[collisions_1]          = ssts.collisions
							,[backoffs_1]            = ssts.backoffs
							,[sleep_time_1]          = ssts.sleep_time		
							,[spins_per_collision_1] = ssts.spins_per_collision
				FROM        StresSQLStats  AS ists
				CROSS JOIN  @SpinlockStats AS ssts
				WHERE       ists.Threads = @i
				AND         ists.Test    = @Test
				AND         ssts.[Rank]  = 1;

				UPDATE      ists
				SET          [spinlock_name_2]       = ssts.name
							,[spins_2]               = ssts.spins
							,[collisions_2]          = ssts.collisions
							,[backoffs_2]            = ssts.backoffs
							,[sleep_time_2]          = ssts.sleep_time		
							,[spins_per_collision_2] = ssts.spins_per_collision
				FROM        StresSQLStats  AS ists
				CROSS JOIN  @SpinlockStats AS ssts
				WHERE       ists.Threads = @i
				AND         ists.Test    = @Test
				AND         ssts.[Rank]  = 2;

				UPDATE      ists
				SET          [spinlock_name_3]       = ssts.name
							,[spins_3]               = ssts.spins
							,[collisions_3]          = ssts.collisions
							,[backoffs_3]            = ssts.backoffs
							,[sleep_time_3]          = ssts.sleep_time		
							,[spins_per_collision_3] = ssts.spins_per_collision
				FROM        StresSQLStats  AS ists
				CROSS JOIN  @SpinlockStats AS ssts
				WHERE       ists.Threads = @i
				AND         ists.Test    = @Test
				AND         ssts.[Rank]  = 3;

				UPDATE      ists
				SET          [spinlock_name_4]       = ssts.name
							,[spins_4]               = ssts.spins
							,[collisions_4]          = ssts.collisions
							,[backoffs_4]            = ssts.backoffs
							,[sleep_time_4]          = ssts.sleep_time		
							,[spins_per_collision_4] = ssts.spins_per_collision
				FROM        StresSQLStats  AS ists
				CROSS JOIN  @SpinlockStats AS ssts
				WHERE       ists.Threads = @i
				AND         ists.Test    = @Test
				AND         ssts.[Rank]  = 4;

				UPDATE      ists
				SET          [spinlock_name_5]       = ssts.name
							,[spins_5]               = ssts.spins
							,[collisions_5]          = ssts.collisions
							,[backoffs_5]            = ssts.backoffs
							,[sleep_time_5]          = ssts.sleep_time		
							,[spins_per_collision_5] = ssts.spins_per_collision
				FROM        StresSQLStats  AS ists
				CROSS JOIN  @SpinlockStats AS ssts
				WHERE       ists.Threads = @i
				AND         ists.Test    = @Test
				AND         ssts.[Rank]  = 5;
			END;	
        END;
		
		SET @i += 1;
	END;
END;
GO
PRINT N'Creating [dbo].[usp_LMaxDiskInit]...';


GO

CREATE PROCEDURE [dbo].[usp_LMaxDiskInit] 
AS
BEGIN
		UPDATE [dbo].[MyQLmax] SET reference_count = 0;
END;
GO
PRINT N'Creating [dbo].[usp_LMaxDiskNumaInit]...';


GO

CREATE PROCEDURE [dbo].[usp_LMaxDiskNumaInit] 
AS
BEGIN
		UPDATE [dbo].[MyQLmaxNode0] SET reference_count = 0;
		UPDATE [dbo].[MyQLmaxNode1] SET reference_count = 0;
END;
GO
PRINT N'Altering [dbo].[usp_LmaxPushImOltpNoSequence]...';


GO
ALTER PROCEDURE [dbo].[usp_LmaxPushImOltpNoSequence] @TransactionsPerThread int = 200000 
AS 
BEGIN 
    DECLARE @i int = 0;

    WHILE @i <= @TransactionsPerThread 
    BEGIN
        EXEC dbo.usp_PushMessageImOltpNoSequence;
		SET @i += 1;
    END;
END;
GO
EXECUTE [dbo].[usp_LMaxDiskQSlotInit];
GO

GO
PRINT N'Update complete.';


GO
