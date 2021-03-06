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
PRINT N'Altering [dbo].[usp_LmaxPopDiskNumaNoSequence]...';


GO
 

ALTER PROCEDURE [dbo].[usp_LmaxPopDiskNumaNoSequence] @TransactionsPerThread int = 200000
AS 
BEGIN 
    DECLARE  @MessagePopped int
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
			EXEC dbo.usp_PopMessageDiskNoSequenceNode0 @MessagePopped OUTPUT; 
			SET @i += 1;
		END;
	END
	ELSE
	BEGIN
		WHILE @i <= @TransactionsPerThread
		BEGIN
			EXEC dbo.usp_PopMessageDiskNoSequenceNode1 @MessagePopped OUTPUT; 
			SET @i += 1;
		END;
	END
END;
GO
PRINT N'Altering [dbo].[usp_LmaxPopDiskNumaSequence]...';


GO


ALTER PROCEDURE [dbo].[usp_LmaxPopDiskNumaSequence] @TransactionsPerThread int = 200000
AS 
BEGIN 
    DECLARE  @MessagePopped int
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
			EXEC dbo.usp_PopMessageDiskSequenceNode0 @MessagePopped OUTPUT; 
			SET @i += 1;
		END;
	END
	ELSE
	BEGIN
		WHILE @i <= @TransactionsPerThread 
		BEGIN
			EXEC dbo.usp_PopMessageDiskSequenceNode1 @MessagePopped OUTPUT; 
			SET @i += 1;
		END;
	END
END;
GO
PRINT N'Altering [dbo].[usp_LmaxPushDiskNoSequence]...';


GO

ALTER PROCEDURE [dbo].[usp_LmaxPushDiskNoSequence] 
AS 
BEGIN 
    DECLARE  @QueueSize     int = 200000
            ,@MessagePopped int
            ,@i             int = 0;

    SET NOCOUNT ON;

	WHILE @i <= @QueueSize 
	BEGIN
		EXEC dbo.usp_PushMessageDiskNoSequence @MessagePopped OUTPUT; 
		SET @i += 1;
	END;
END;
GO
PRINT N'Altering [dbo].[usp_LmaxPushDiskNumaNoSequence]...';


GO

ALTER PROCEDURE [dbo].[usp_LmaxPushDiskNumaNoSequence] 
AS 
BEGIN 
    DECLARE  @QueueSize     int = 200000
            ,@MessagePushed int
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
		WHILE @i <= @QueueSize 
		BEGIN
			EXEC dbo.usp_PushMessageDiskNoSequenceNode0 @MessagePushed OUTPUT; 
			SET @i += 1;
		END;
	END
	ELSE
	BEGIN
		WHILE @i <= @QueueSize 
		BEGIN
			EXEC dbo.usp_PushMessageDiskNoSequenceNode1 @MessagePushed OUTPUT; 
			SET @i += 1;
		END;
	END
END;
GO
PRINT N'Altering [dbo].[usp_LmaxPushDiskNumaSequence]...';


GO

ALTER PROCEDURE [dbo].[usp_LmaxPushDiskNumaSequence] 
AS 
BEGIN 
    DECLARE  @QueueSize     int = 200000
            ,@MessagePushed int
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
		WHILE @i <= @QueueSize 
		BEGIN
			EXEC dbo.usp_PushMessageDiskSequenceNode0 @MessagePushed OUTPUT; 
			SET @i += 1;
		END;
	END
	ELSE
	BEGIN
		WHILE @i <= @QueueSize 
		BEGIN
			EXEC dbo.usp_PushMessageDiskSequenceNode1 @MessagePushed OUTPUT; 
			SET @i += 1;
		END;
	END
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
    END;
END;
GO
PRINT N'Creating [dbo].[usp_PushMessageImOltpSequence]...';


GO


CREATE PROCEDURE [dbo].[usp_PushMessageImOltpSequence] @MessagePushed int OUTPUT
AS
BEGIN 
    DECLARE  @QueueSize int    = 4000000
	        ,@Message   char(300)
	        ,@Slot      bigint;

	SET @MessagePushed = 0;

	WHILE @MessagePushed = 0
	BEGIN
		EXEC [dbo].[usp_GetPushSlotId] @Slot OUTPUT, @QueueSize;
        EXEC [dbo].[usp_PushMessageImOltpSequence] @@MessagePushed OUTPUT;
	END;
END;
GO
PRINT N'Creating [dbo].[usp_LmaxPushImOltpSequence]...';


GO
CREATE PROCEDURE [dbo].[usp_LmaxPushImOltpSequence] @TransactionsPerThread int = 200000
AS 
BEGIN 
    DECLARE  @QueueSize     int = 200000
            ,@i             int = 0;

    WHILE @i <= @TransactionsPerThread 
    BEGIN
        EXEC dbo.usp_PushMessageImOltpSequence
    END;
END;
GO
/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/
EXECUTE [dbo].[usp_LMaxDiskQSlotInit];
GO

GO
PRINT N'Update complete.';


GO
