CREATE TABLE [dbo].[NonBlockingSequenceHashIndex]
(
	[ID]  [bigint] IDENTITY(1,1) NOT NULL,
	[Val] [bigint]
 PRIMARY KEY NONCLUSTERED HASH 
(
	[ID]
)WITH ( BUCKET_COUNT = 4000000)
)WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_ONLY )

GO

