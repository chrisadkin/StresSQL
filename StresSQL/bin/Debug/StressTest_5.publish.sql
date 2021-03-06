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
PRINT N'Altering [dbo].[usp_LMaxDiskQSlotInit]...';


GO

ALTER PROCEDURE [dbo].[usp_LMaxDiskQSlotInit]  
AS
BEGIN 
    DECLARE  @QueueSize int = 4000000
	        ,@Slot      bigint
	        ,@i         int = 0;

	SET NOCOUNT ON;

	WHILE @i < @QueueSize
	BEGIN
		SET @Slot = (CASE RIGHT(@i, 1)
						 WHEN 1
							 THEN @i + 5000000000
						 WHEN 2
							 THEN @i + 1000000000
						 WHEN 3
							 THEN @i + 8000000000
						 WHEN 4
							 THEN @i + 2000000000
						 WHEN 5
							 THEN @i + 7000000000
						 WHEN 6
							 THEN @i + 3000000000
						 WHEN 7
							 THEN @i + 6000000000
						 WHEN 8
							 THEN @i + 4000000000
						 WHEN 9
							 THEN @i + 9000000000
						 ELSE
							 @i
					 END );			

		INSERT INTO [dbo].[MyQLmax]
			   ([Slot]
			   ,[message_id]
			   ,[time]
			   ,[message]
			   ,[reference_count])
		 VALUES
			   (@Slot
			   ,0
			   ,GETDATE()
			   ,''
			   ,0);
		SET @i += 1;
	END;

	INSERT INTO [dbo].[MyQLmaxNode0]
			([Slot]
			,[message_id]
			,[time]
			,[message]
			,[reference_count])
	SELECT   [Slot]
			,[message_id]
			,[time]
			,[message]
			,[reference_count]
	FROM     [dbo].[MyQLmax];

	INSERT INTO [dbo].[MyQLmaxNode1]
			([Slot]
			,[message_id]
			,[time]
			,[message]
			,[reference_count])
	SELECT   [Slot]
			,[message_id]
			,[time]
			,[message]
			,[reference_count]
	FROM     [dbo].[MyQLmax];
END;
GO
PRINT N'Creating [dbo].[usp_LMaxNumaInit]...';


GO

CREATE PROCEDURE [dbo].[usp_LMaxNumaInit] 
AS
BEGIN
		UPDATE [dbo].[MyQLmaxNode0] SET reference_count = 0;
		UPDATE [dbo].[MyQLmaxNode1] SET reference_count = 0;
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
