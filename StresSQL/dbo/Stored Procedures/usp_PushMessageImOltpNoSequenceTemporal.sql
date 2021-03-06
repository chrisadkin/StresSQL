﻿CREATE PROCEDURE [dbo].[usp_PushMessageImOltpNoSequenceTemporal]  
WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC
    WITH ( TRANSACTION ISOLATION LEVEL = SNAPSHOT
          ,LANGUAGE                    = N'us_english')

    DECLARE  @MessagePushed int
	        ,@QueueSize     int = 4000000
			,@Slot          bigint;

	SET @MessagePushed = 0;

	WHILE @MessagePushed = 0
	BEGIN
		INSERT INTO [dbo].[NonBlockingPushSequence]
			DEFAULT VALUES;

		SELECT @Slot = SCOPE_IDENTITY();
	
		DELETE FROM [dbo].[NonBlockingPushSequence] WHERE ID = @Slot;
		
		UPDATE [dbo].[MyQLmaxImOltpTemporal]
		SET     time            = GETDATE()
			   ,message         = 'Hello world'
			   ,message_id      = @Slot
			   ,reference_count = reference_count + 1
		WHERE   Slot            = @Slot % @QueueSize
		AND     reference_count = 0;

		SET @MessagePushed = @@ROWCOUNT;
	END;
END;